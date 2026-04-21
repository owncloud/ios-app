import Foundation
import Network
import Combine
import RegexBuilder

public struct LocalDevice: Sendable, Codable {
    public let name: String
    public let host: String
    public let port: Int
    public let certificateCommonName: String?
	public let oobeIsDone: Bool
}

private enum Constants {
	static let mDNSServiceType = "_https._tcp"
	static func isHomeCloud(_ name: String) -> Bool {
		name.range(of: "homecloud", options: [.caseInsensitive]) != nil
	}
}

public final class MDNSService {
	private var browser: NWBrowser?

	private var results: [LocalDevice] = []
	public var onUpdate: (([LocalDevice]) -> Void)?

	// MARK: - Combine stream
	private let discoveredSubject = PassthroughSubject<LocalDevice, Never>()
	private let devicesSubject = CurrentValueSubject<[LocalDevice], Never>([])
	public var devicesPublisher: AnyPublisher<[LocalDevice], Never> { devicesSubject.eraseToAnyPublisher() }
	private var cancellables = Set<AnyCancellable>()

	public init() {}

	public func start() {
		let descriptor = NWBrowser.Descriptor.bonjour(type: Constants.mDNSServiceType, domain: nil)
		let params = NWParameters()
		params.includePeerToPeer = true

		let browser = NWBrowser(for: descriptor, using: params)
		self.browser = browser

		browser.stateUpdateHandler = { state in
			Log.debug("[STX-MDNS]: Browser state: \"\(state)\"")

			switch state {
				case .failed(let error):
					if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
						browser.cancel()
						Log.debug("[STX-MDNS]: Browser state DefunctConnection. Restarting browser")
						self.start()
					} else {
						Log.debug("[STX-MDNS]: Browser failed with error \(error). Stopping.")
						browser.cancel()
					}

				default:
					break
			}
		}

		browser.browseResultsChangedHandler = { _, changes in
			// Spec Phase 1: only process newly added or changed services — not the full result
			// set on every event. Re-resolving all known services on each change causes redundant
			// about/status HTTP requests for already-validated devices.
			for change in changes {
				switch change {
				case .added(let result), .changed(_, let result, _):
					guard case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint else { continue }
					guard Constants.isHomeCloud(name) else { continue }
					self.resolve(result: result)
					Log.debug("[STX-MDNS]: Found service: \"\(name)\"")

				case .removed(let result):
					// Spec: when a service disappears, remove it from the local device list
					// immediately so stale entries don't accumulate until WiFi loss or restart.
					guard case let .service(name: name, type: _, domain: _, interface: _) = result.endpoint else { continue }
					guard Constants.isHomeCloud(name) else { continue }
					self.remove(byName: name)
					Log.debug("[STX-MDNS]: Removed service: \"\(name)\"")

				@unknown default:
					break
				}
			}
		}

		browser.start(queue: .main)

		discoveredSubject
			.flatMap { [weak self] device -> AnyPublisher<LocalDevice, Never> in
				guard let self else { return Just(device).eraseToAnyPublisher() }

				return self.aboutPublisher(for: device)
			}
			.receive(on: DispatchQueue.main)
			.sink { [weak self] updated in
				guard let self else { return }

				self.upsert(updated)
				// Spec Phase 1 step 5: "if the call succeeds, create or update the logical device."
				// Only propagate devices that passed about validation (have a certificateCommonName).
				// Devices whose about endpoint failed or timed out remain in `results` internally
				// but must not enter the merged device map without a confirmed CN.
				let validated = results.filter { $0.certificateCommonName != nil }
				self.onUpdate?(validated)
				self.devicesSubject.send(results)
			}
			.store(in: &cancellables)
	}

	public func stop() {
		browser?.cancel()
		browser = nil
		// Spec cancel-and-restart: tear down the Combine pipeline and clear accumulated results
		// so a subsequent start() creates a fresh discovery session from a clean slate.
		cancellables.removeAll()
		results = []
	}

	public func currentDevices() -> [LocalDevice] {
		results
	}

	private func resolve(result: NWBrowser.Result) {
		guard case let .service(name, type, domain, _) = result.endpoint else { return }
		let params = NWParameters.tcp
		let endpoint = NWEndpoint.service(name: name, type: type, domain: domain, interface: nil)
		let conn = NWConnection(to: endpoint, using: params)
		var emitted = false
		func emit(_ entry: LocalDevice) {
			guard emitted == false else { return }
			emitted = true
			self.upsert(entry)
			self.discoveredSubject.send(entry)
		}
		conn.stateUpdateHandler = { state in
			if case .ready = state {
				if case let .hostPort(host, port) = conn.currentPath?.remoteEndpoint {
					let portValue = Int(port.rawValue)
					let hostString: String?

					switch host {
						case let .ipv4(addr):
							hostString = addr.string

						case let .ipv6(addr):
							hostString = addr.string

					case let .name(name, _):
						// mDNS names often end with a trailing dot; strip it to get a valid hostname.
						hostString = name.hasSuffix(".") ? String(name.dropLast()) : name

					@unknown default:
							hostString = nil
					}
					guard let hostString else {
						Log.debug("[STX-MDNS]: Host is empty for \(host), ignoring.")
						return
					}
					Log.debug("[STX-MDNS]: Resolved \"\(name)\" to \"\(hostString):\(port)\"")
					// Accept only IPv4 non-link-local; otherwise try Wi‑Fi-only resolve
					if self.isIPv4(hostString) && self.isLinkLocal(hostString) == false {
						emit(LocalDevice(
						name: name,
						host: hostString,
						port: portValue,
						certificateCommonName: nil,
						oobeIsDone: false
						))
					} else {
						// Try Wi‑Fi-only to get an IPv4 non-link-local address
						let wifiParams = NWParameters.tcp
						wifiParams.requiredInterfaceType = .wifi
						let wifiConn = NWConnection(to: endpoint, using: wifiParams)
						wifiConn.stateUpdateHandler = { wifiState in
							if case .ready = wifiState {
								if case let .hostPort(wifiHost, wifiPort) = wifiConn.currentPath?.remoteEndpoint {
									let wifiPortValue = Int(wifiPort.rawValue)
									let wifiHostString: String?
									switch wifiHost {
										case let .ipv4(addr):
											wifiHostString = addr.string
										case let .ipv6(addr):
											wifiHostString = addr.string
									case let .name(name, _):
										wifiHostString = name.hasSuffix(".") ? String(name.dropLast()) : name
									@unknown default:
											wifiHostString = nil
									}
									if let wifiHostString, self.isIPv4(wifiHostString), self.isLinkLocal(wifiHostString) == false {
										Log.debug("[STX-MDNS]: Preferred IPv4 Wi‑Fi address for \"\(name)\" -> \"\(wifiHostString):\(wifiPort)\"")
										emit(LocalDevice(
											name: name,
											host: wifiHostString,
											port: wifiPortValue,
											certificateCommonName: nil,
											oobeIsDone: false
										))
										wifiConn.cancel()
										return
									}
								}
								// Wi‑Fi gave no IPv4 non-link-local; do not emit
								wifiConn.cancel()
							} else if case .failed = wifiState {
								// Fallback failed; do not emit
							}
						}
						// Safety timeout for fallback
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
							wifiConn.cancel()
						}
						wifiConn.start(queue: .main)
					}
				}
				conn.cancel()
			}
		}
		conn.start(queue: .main)
	}

	private func isLinkLocal(_ host: String) -> Bool {
		// IPv4 link-local: 169.254.0.0/16
		if host.hasPrefix("169.254.") { return true }
		// IPv6 link-local typically starts with fe80::/10 (allowing fe8, fe9, fea, feb)
		let lower = host.lowercased()
		if lower.hasPrefix("fe80:") || lower.hasPrefix("fe80::") { return true }
		return false
	}

	private func isIPv4(_ host: String) -> Bool {
		// Simple heuristic: contains exactly 3 dots and all octets are digits
		let parts = host.split(separator: ".")
		if parts.count != 4 { return false }
		for p in parts {
			if p.isEmpty || p.contains(where: { $0 < "0" || $0 > "9" }) { return false }
		}
		return true
	}

	private func upsert(_ entry: LocalDevice) {
		if let idx = results.firstIndex(where: { $0.name == entry.name }) {
			let existing = results[idx]
			// Preserve a previously validated CN — don't silently demote it to nil if a
			// subsequent about re-resolve fails (e.g. due to a transient timeout).
			let resolvedCN = entry.certificateCommonName ?? existing.certificateCommonName
			let resolvedOOBE = entry.certificateCommonName != nil ? entry.oobeIsDone : existing.oobeIsDone
			results[idx] = LocalDevice(
				name: entry.name,
				host: entry.host,
				port: entry.port,
				certificateCommonName: resolvedCN,
				oobeIsDone: resolvedOOBE
			)
		} else {
			results.append(entry)
		}
	}

	private func remove(byName name: String) {
		results.removeAll { $0.name == name }
		let validated = results.filter { $0.certificateCommonName != nil }
		onUpdate?(validated)
		devicesSubject.send(results)
	}

	private func aboutPublisher(for device: LocalDevice) -> AnyPublisher<LocalDevice, Never> {
		Future<LocalDevice, Never> { promise in
			Task {
				do {
					guard let baseURL = URL(string: "https://\(device.host):\(device.port)/") else {
						promise(.success(device))
						return
					}

					let api = DeviceAPI(deviceBaseURL: baseURL)

					// Spec: local API timeout for `about` is 4 seconds total.
					// Race the status+about sequence against a 4-second deadline.
					let resolved: LocalDevice = try await withThrowingTaskGroup(of: LocalDevice.self) { group in
						group.addTask {
							// Spec: the about endpoint is the required validation call.
							// getStatus() is supplementary (OOBE state); treat it as optional
							// so a slow status response cannot block CN validation.
							let about = try await api.getAbout()
							let status = try? await api.getStatus()
							return LocalDevice(
								name: device.name,
								host: device.host,
								port: device.port,
								certificateCommonName: about.certificate_common_name,
								oobeIsDone: status?.OOBE.done ?? false
							)
						}
						group.addTask {
							try await Task.sleep(nanoseconds: 4_000_000_000)
							throw CancellationError()
						}
						let result = try await group.next()!
						group.cancelAll()
						return result
					}
					promise(.success(resolved))
				} catch {
					Log.debug("[STX-MDNS]: Got error resolving device: \(error)")
					promise(.success(device))
				}
			}
		}.eraseToAnyPublisher()
	}
}
