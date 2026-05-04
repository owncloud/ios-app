import Foundation
import ownCloudSDK

/// Spec Algorithm D — the network-change FSM.
///
/// Owns:
///   - the FSM itself (`coordinatorState` + `CoordinatorEvent` transitions),
///   - the foreground/background gate,
///   - the cooldown timer,
///   - the reference-counted `detectionsInFlight` flag,
///   - the auth gate that re-prompts for email validation when tokens expire,
///   - the actual detection trigger (`performDetection(for:)`) which decides between
///     Algorithm B (direct resolution via the pipeline's resolver) and Algorithm A
///     (full reload via the pipeline).
///
/// External entry points that bypass the FSM (init bootstrap, public
/// `forceReloadDevices()`, transport-failure reprobe) bracket their direct call into
/// the pipeline with `beginExternalDetection()` / `endExternalDetection()` so the FSM
/// stays accurate and concurrent network-change events queue rather than spawn a third
/// detection.
public actor NetworkChangeCoordinator {
	public typealias EmitEvent = @Sendable (DeviceReachabilityEvent) -> Void

	private enum CoordinatorState: Sendable {
		case idle
		case waitingForCooldown(expiresAt: Date, queued: NetworkState)
		case detecting(queued: NetworkState?)
	}

	public enum CoordinatorEvent: Sendable {
		/// Debounced reachability update (3 s after the OS notification).
		case networkStateChanged(NetworkState)
		case appBecameActive
		case appResignedActive
		/// Cooldown timer fired; the queued state lives in `.waitingForCooldown`.
		case cooldownExpired
		/// A `reloadDevices()` invocation finished (any caller).
		case detectionFinished
	}

	private let pipeline: DetectionPipeline
	private let remoteAccessService: RemoteAccessService
	private let preferences: HCPreferences
	private let availabilityMonitor: NetworkAvailabilityMonitor
	private let emit: EmitEvent

	private var coordinatorState: CoordinatorState = .idle
	private var isForeground: Bool = true
	private var queuedWhileBackgrounded: NetworkState?
	/// Reference count of in-flight detection runs (FSM- and externally-initiated).
	/// Only the last one to finish moves the FSM out of `.detecting`, so a transport-failure
	/// reprobe arriving during a network-change detection doesn't prematurely flip us to
	/// `.idle` and let a third run start before either has cleared `remotePathProbesByCN`.
	private var detectionsInFlight: Int = 0
	/// Anchor for the 30-second cooldown between network-change-triggered detections.
	private var lastDetectionAt: Date?
	private let detectionCooldownSeconds: TimeInterval = 30
	/// Coordinator-internal: holds the deferred `cooldownExpired` Task while in
	/// `.waitingForCooldown`. `nil` in every other coordinator state.
	private var cooldownTask: Task<Void, Never>?
	/// Last seen network state, kept for interface-type comparison so a cellular → WiFi
	/// transition can clear the cooldown.
	private var lastNetworkState: NetworkState?
	/// Spec: the first reachability event is the initial known state and should not trigger re-detection.
	private var hasSeenInitialNetworkState: Bool = false

	public init(
		pipeline: DetectionPipeline,
		remoteAccessService: RemoteAccessService,
		preferences: HCPreferences,
		availabilityMonitor: NetworkAvailabilityMonitor,
		emit: @escaping EmitEvent
	) {
		self.pipeline = pipeline
		self.remoteAccessService = remoteAccessService
		self.preferences = preferences
		self.availabilityMonitor = availabilityMonitor
		self.emit = emit
	}

	// MARK: - Public entry points

	/// Single entry point for everything that can move the coordinator. Each event has
	/// exactly one transition handler — the spec ordering rules are encoded there once
	/// rather than re-implemented at every call site.
	public func handle(_ event: CoordinatorEvent) async {
		switch event {
			case .networkStateChanged(let state):
				await onNetworkStateChanged(state)
			case .appBecameActive:
				await onAppBecameActive()
			case .appResignedActive:
				onAppResignedActive()
			case .cooldownExpired:
				await onCooldownExpired()
			case .detectionFinished:
				await onDetectionFinished()
		}
	}

	/// Bracket called by external entry points (init bootstrap, transport-failure reprobe,
	/// public `forceReloadDevices()`) right before they invoke `pipeline.reloadDevices()`
	/// directly. Keeps `.detecting` in sync so concurrent network-change events queue
	/// rather than spawn a third detection.
	public func beginExternalDetection() {
		switch coordinatorState {
			case .idle:
				cancelCooldown()
				lastDetectionAt = Date()
				coordinatorState = .detecting(queued: nil)
			case .waitingForCooldown(_, let queued):
				cancelCooldown()
				lastDetectionAt = Date()
				coordinatorState = .detecting(queued: queued)
			case .detecting:
				break
		}
		detectionsInFlight += 1
	}

	/// Companion to `beginExternalDetection()`. Decrements `detectionsInFlight` and runs
	/// the same drain logic as an FSM-internal detection finish.
	public func endExternalDetection() async {
		await onDetectionFinished()
	}

	/// Resets the FSM after a logout / cache wipe so we don't retain a stale `.detecting`
	/// or queued state. Any in-flight detection will still call `.detectionFinished`,
	/// which is a safe no-op when the FSM is already `.idle` and the in-flight count is 0.
	public func reset() {
		cancelCooldown()
		coordinatorState = .idle
		queuedWhileBackgrounded = nil
		detectionsInFlight = 0
	}

	/// Tear-down hook for `uninstallReloadTriggers`.
	public func cancelCooldownTask() {
		cancelCooldown()
	}

	// MARK: - Transitions

	private func onNetworkStateChanged(_ state: NetworkState) async {
		// Spec Algorithm D: drop the very first event — it represents the initial known state,
		// not an actual change. Record it so subsequent events can be compared against it.
		guard hasSeenInitialNetworkState else {
			hasSeenInitialNetworkState = true
			lastNetworkState = state
			return
		}

		// We intentionally do NOT early-return on `last.interface == state.interface`.
		// `NetworkState.interface` is too coarse to distinguish WiFi A from WiFi B, so a
		// same-type switch (WiFi → WiFi between two SSIDs) would otherwise be dropped.
		// Every event flows through the cooldown gate below, which is what actually
		// rate-limits redundant detections.
		let interfaceTypeChanged = lastNetworkState.map { $0.interface != state.interface } ?? true
		if interfaceTypeChanged {
			// Topology change (WiFi → cellular, hotspot, …). Reset the cooldown so detection
			// fires immediately after the 3 s debounce, and re-arm the toast (clears the
			// dismissal latch so the "Finding network…" toast can reappear).
			lastDetectionAt = nil
			Task { [availabilityMonitor] in await availabilityMonitor.recordNetworkChange() }
		}
		lastNetworkState = state

		// Background gate: defer everything until foreground. Cancel any in-flight cooldown
		// so it doesn't fire in the background and have to be re-routed on expiry.
		guard isForeground else {
			cancelCooldown()
			if case .detecting = coordinatorState {
				coordinatorState = .detecting(queued: state)
			} else {
				coordinatorState = .idle
				queuedWhileBackgrounded = state
				Log.debug("[STX-RA]: Network change deferred (app not active). Interface: \(state.interface.rawValue).")
			}
			return
		}

		// Auth gate: unconditional, not gated on favoriteEmail. The FSM doesn't latch — the
		// next event (token refresh, another network change) will retry.
		let hasToken = await remoteAccessService.hasValidTokens()
		if !hasToken {
			if let email = preferences.favoriteEmail {
				emit(.emailValidationNeeded(email: email))
			}
			return
		}

		switch coordinatorState {
			case .detecting:
				coordinatorState = .detecting(queued: state)
				Log.debug("[STX-RA]: Network change deferred — full detection already in progress.")
			case .waitingForCooldown(let expiresAt, _):
				coordinatorState = .waitingForCooldown(expiresAt: expiresAt, queued: state)
			case .idle:
				if let last = lastDetectionAt {
					let elapsed = Date().timeIntervalSince(last)
					if elapsed < detectionCooldownSeconds {
						let wait = detectionCooldownSeconds - elapsed
						let expiresAt = Date().addingTimeInterval(wait)
						Log.debug("[STX-RA]: Cooldown active; deferring re-detection by \(Int(wait))s.")
						scheduleCooldown(expiresAt: expiresAt)
						coordinatorState = .waitingForCooldown(expiresAt: expiresAt, queued: state)
						return
					}
				}
				startDetection(for: state)
		}
	}

	private func onAppBecameActive() async {
		isForeground = true
		guard let pending = queuedWhileBackgrounded else { return }
		queuedWhileBackgrounded = nil
		Log.debug("[STX-RA]: Processing deferred network change on foreground. Interface: \(pending.interface.rawValue).")
		await onNetworkStateChanged(pending)
	}

	private func onAppResignedActive() {
		isForeground = false
		// If a cooldown is ticking, cancel it and roll the queued state into
		// `queuedWhileBackgrounded` so it gets re-evaluated on foreground return — cleaner
		// than letting the timer fire in the background and re-route on expiry.
		if case .waitingForCooldown(_, let queued) = coordinatorState {
			cancelCooldown()
			queuedWhileBackgrounded = queued
			coordinatorState = .idle
		}
	}

	private func onCooldownExpired() async {
		guard case .waitingForCooldown(_, let queued) = coordinatorState else { return }
		cooldownTask = nil
		// The cooldown can be up to 30 s — plenty of time for the app to background or
		// tokens to expire. Re-check both gates before kicking off detection.
		guard isForeground else {
			Log.debug("[STX-RA]: Cooldown fired while app is in background — re-deferred to foreground.")
			coordinatorState = .idle
			queuedWhileBackgrounded = queued
			return
		}
		let hasToken = await remoteAccessService.hasValidTokens()
		if !hasToken {
			if let email = preferences.favoriteEmail {
				emit(.emailValidationNeeded(email: email))
			}
			coordinatorState = .idle
			return
		}
		startDetection(for: queued)
	}

	private func onDetectionFinished() async {
		// Decrement first so reference-counted external/internal detections finishing in any
		// order all collapse to a single `.idle` transition once the last one returns.
		detectionsInFlight = max(0, detectionsInFlight - 1)
		guard detectionsInFlight == 0 else { return }
		guard case .detecting(let queued) = coordinatorState else { return }
		coordinatorState = .idle
		guard let queued else { return }
		if !isForeground {
			queuedWhileBackgrounded = queued
			return
		}
		Log.debug("[STX-RA]: Processing deferred network change after detection finished. Interface: \(queued.interface.rawValue).")
		Task { await self.handle(.networkStateChanged(queued)) }
	}

	// MARK: - Helpers

	/// Stamps `lastDetectionAt = now`, transitions to `.detecting(nil)`, and kicks off
	/// `performDetection(for:)` in a Task. Returning from `startDetection` does not wait
	/// for detection to complete; completion is reported via `.detectionFinished`.
	private func startDetection(for state: NetworkState) {
		Log.debug("[STX-RA]: Network state: \(state)")
		cancelCooldown()
		lastDetectionAt = Date()
		coordinatorState = .detecting(queued: nil)
		detectionsInFlight += 1
		Task { [weak self] in
			await self?.performDetection(for: state)
			await self?.handle(.detectionFinished)
		}
	}

	/// Direct path resolution if the seagateDeviceID is already known (Algorithm B), else
	/// a full reload (Algorithm A). Auth is re-checked defensively because cooldown windows
	/// can outlast a token's lifetime.
	///
	/// The `state` argument is currently unused but kept for parity with the spec; the
	/// pipeline derives `wifiAvailable` from its injected reachability service.
	private func performDetection(for state: NetworkState) async {
		_ = state
		let hasToken = await remoteAccessService.hasValidTokens()
		if !hasToken {
			if let email = preferences.favoriteEmail {
				emit(.emailValidationNeeded(email: email))
			}
			return
		}
		if let saved = preferences.currentConnectedDevice,
		   let seagateDeviceID = saved.seagateDeviceID,
		   !seagateDeviceID.isEmpty {
			let wifiAvailable = pipeline.wifiAvailableForLocalPaths
			let resolved = await pipeline.attemptDirectResolution(
				seagateDeviceID: seagateDeviceID,
				certificateCommonName: saved.certificateCommonName,
				wifiAvailable: wifiAvailable
			)
			if resolved { return }
		}
		await pipeline.reloadDevices()
	}

	/// Schedules a Task that fires `.cooldownExpired` after `expiresAt`. Replaces any
	/// previous `cooldownTask` so the latest queued state always wins.
	private func scheduleCooldown(expiresAt: Date) {
		cooldownTask?.cancel()
		let delay = max(0, expiresAt.timeIntervalSince(Date()))
		cooldownTask = Task { [weak self] in
			try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
			guard let self, !Task.isCancelled else { return }
			await self.handle(.cooldownExpired)
		}
	}

	private func cancelCooldown() {
		cooldownTask?.cancel()
		cooldownTask = nil
	}
}
