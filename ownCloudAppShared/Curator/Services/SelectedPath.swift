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
}
