import Foundation
import ownCloudSDK

/// A single concrete URL that the SDK should attempt next, tagged with whether it came from
/// remote-access discovery or local mDNS.
public enum SelectedPath: Sendable {
	case remote(RemoteDevice.Path)
	case mdns(host: String, port: Int)

	public var url: URL? {
		switch self {
			case let .mdns(host, port):
				return URL(host: host, port: port)
			case let .remote(path):
				return URL(host: path.address, port: path.port)
		}
	}

	/// Stable key stored in `HCPreferences.SavedConnectedDevice.lastSuccessfulPathKey`.
	public var persistenceKey: String {
		switch self {
			case let .remote(path):
				return path.key
			case let .mdns(host, port):
				return "mdns|\(host)|\(port)"
		}
	}

	/// Resolves a persisted path key against known remote paths and optional mDNS local.
	public static func matching(
		persistenceKey key: String,
		paths: [RemoteDevice.Path],
		localDevice: LocalDevice?,
		wifiAvailable: Bool
	) -> SelectedPath? {
		if key.hasPrefix("mdns|") {
			guard wifiAvailable else { return nil }
			let parts = key.split(separator: "|", omittingEmptySubsequences: false)
			guard parts.count == 3, let port = Int(parts[2]) else { return nil }
			let host = String(parts[1])
			if let local = localDevice, local.host == host, local.port == port {
				return .mdns(host: host, port: port)
			}
			return .mdns(host: host, port: port)
		}
		if let path = paths.first(where: { $0.key == key }) {
			return .remote(path)
		}
		return nil
	}
}

public extension HCPreferences.SavedConnectedDevice.SavedPath {
	/// Matches `RemoteDevice.Path.key`.
	var pathKey: String {
		"\(kind.rawValue)|\(address)|\(port ?? -1)"
	}

	func asRemotePath() -> RemoteDevice.Path {
		let kind: RemoteDevice.Path.Kind = switch self.kind {
			case .local: .local
			case .public: .public
			case .remote: .remote
		}
		return RemoteDevice.Path(kind: kind, address: address, port: port)
	}
}
