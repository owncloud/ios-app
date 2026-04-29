import Foundation

/// Which message the toast should display.
///
/// - `findingNetwork`: the system reports no usable path (airplane mode, Wi-Fi off,
///   cellular off). Surfaced as "Finding network…".
/// - `noInternet`: the system reports a usable path (Wi-Fi/cellular up) but every
///   request still fails — the classic "liar network" / bad-proxy scenario.
///   Surfaced as "No internet".
public enum NetworkAvailabilityToastKind: Sendable, Equatable {
	case findingNetwork
	case noInternet
}

/// Tracks whether *any* of the candidate URLs (local, public, remote) is producing successful
/// responses, and decides when to surface the connectivity toast.
///
/// Behavior contract (see spec):
/// - The toast appears only after **30 seconds** without a successful response from any URL.
/// - Normal URL switching that completes within 30 s does not show the toast.
/// - User dismissal latches: the toast does not reappear until *either* a network state change
///   *or* a success → failure cycle (connection restored and lost again).
/// - Background retries continue without re-stacking the toast.
public final actor NetworkAvailabilityMonitor {
	public static let shared = NetworkAvailabilityMonitor()

	private let timeoutSeconds: TimeInterval = 30

	/// True when at least one URL responded successfully on the most recent attempt.
	/// Initial value is `true` so a freshly-launched app does not show the toast until at
	/// least one failure is observed..
	private var isReachable: Bool = true

	/// When the current continuous-failure streak began. `nil` means we are not currently
	/// in a failure streak.
	private var failureStartTime: Date?

	/// The kind of failure currently being tracked. Updated on every `recordFailure(kind:)`
	/// call so the most recent classification (system-no-path vs liar-network) wins when
	/// the 30 s timer eventually fires.
	private var currentKind: NetworkAvailabilityToastKind = .findingNetwork

	/// Set when the user dismisses the toast. Cleared on a network state change OR on a
	/// successful response so the toast can show again per the spec.
	private var isDismissed: Bool = false

	/// Latched "currently visible" state, mirrored to observers via `visibilityHandler`.
	private var visibleKind: NetworkAvailabilityToastKind?

	/// Pending 30-second wait. Cancelled on success / dismissal / network change so we
	/// never fire stale shows after the streak has ended.
	private var pendingShowTask: Task<Void, Never>?

	private var visibilityHandler: (@MainActor (NetworkAvailabilityToastKind?) -> Void)?

	public init() {}

	// MARK: - Observation

	/// Receives the toast kind to display, or `nil` to hide. Replays the current visibility
	/// synchronously after registering.
	public func observeToastVisibility(_ handler: @escaping @MainActor (NetworkAvailabilityToastKind?) -> Void) {
		visibilityHandler = handler
		let snapshot = visibleKind
		Task { @MainActor in handler(snapshot) }
	}

	// MARK: - Signals from the connectivity layer

	/// Called when at least one URL (local, public, or remote) returned a successful
	/// response. Cancels any pending toast and resets the dismissal latch so the toast
	/// can appear again on the next failure cycle.
	public func recordSuccess() async {
		isReachable = true
		failureStartTime = nil
		pendingShowTask?.cancel()
		pendingShowTask = nil
		isDismissed = false
		if visibleKind != nil {
			visibleKind = nil
			emitVisibility(nil)
		}
	}

	/// Called when an attempt to reach any URL failed (no successful probe / SDK transport
	/// error). Starts the 30-second timer if we were previously reachable.
	///
	/// `kind` selects which message will be shown when the timer fires. If a failure streak
	/// is already in progress and a later signal arrives with a different classification
	/// (e.g. interface drops mid-streak), the kind is updated so the toast reflects the
	/// current state.
	public func recordFailure(kind: NetworkAvailabilityToastKind) async {
		currentKind = kind
		// Only (re)start the timer when transitioning into an unreachable state.
		// Continued failures during an existing streak must not extend the deadline.
		if isReachable || failureStartTime == nil {
			isReachable = false
			failureStartTime = Date()
			schedulePendingShowIfNeeded()
		} else if visibleKind != nil, visibleKind != kind {
			// Streak continues but the classification changed — swap the visible message.
			visibleKind = kind
			emitVisibility(kind)
		}
	}

	/// Called when the system reachability state changes (e.g. WiFi ↔ Cellular). Per
	/// spec, this clears the dismissal latch so the toast can reappear after another
	/// 30 s of failure. Restarts the timer if we are currently failing.
	public func recordNetworkChange() async {
		isDismissed = false
		if !isReachable {
			failureStartTime = Date()
			schedulePendingShowIfNeeded()
		}
	}

	/// User tapped the dismiss (×) button on the toast.
	public func dismiss() async {
		isDismissed = true
		pendingShowTask?.cancel()
		pendingShowTask = nil
		if visibleKind != nil {
			visibleKind = nil
			emitVisibility(nil)
		}
	}

	// MARK: - Internal

	private func schedulePendingShowIfNeeded() {
		pendingShowTask?.cancel()
		guard !isDismissed else { return }
		let snapshot = failureStartTime
		let wait = timeoutSeconds
		pendingShowTask = Task { [weak self] in
			let nanos = UInt64(wait * 1_000_000_000)
			try? await Task.sleep(nanoseconds: nanos)
			guard !Task.isCancelled else { return }
			await self?.fireShow(matching: snapshot)
		}
	}

	private func fireShow(matching snapshot: Date?) {
		// Bail out if anything changed while we were sleeping: a success arrived,
		// the user dismissed the toast, or a newer failure started a fresh window.
		guard !isDismissed,
			  !isReachable,
			  failureStartTime == snapshot else { return }
		guard visibleKind == nil else { return }
		visibleKind = currentKind
		emitVisibility(currentKind)
	}

	private func emitVisibility(_ kind: NetworkAvailabilityToastKind?) {
		guard let handler = visibilityHandler else { return }
		Task { @MainActor in handler(kind) }
	}
}
