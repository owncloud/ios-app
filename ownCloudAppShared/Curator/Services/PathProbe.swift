import Foundation
import ownCloudSDK

/// Result of probing a single network path (local mDNS, public, or remote relay).
public struct PathProbe: Sendable, Codable {
	public enum Source: Sendable, Codable {
		case remotePath(RemoteDevice.Path)
		case mdns(host: String, port: Int)
	}
	public let source: Source
	public let status: Status?
	public let about: About?

	public init(source: Source, status: Status?, about: About?) {
		self.source = source
		self.status = status
		self.about = about
	}

	/// True when both the `status` and `about` endpoints returned *any* response.
	///
	/// Use for connectivity decisions ("did we hear from the box at all?") such as the
	/// "Finding network…" / "No internet" toast. A probe that did not respond is dropped
	/// from the per-device map, so probes that exist always satisfy `hasResponded`.
	public var hasResponded: Bool {
		status != nil && about != nil
	}

	/// True when the box is ready for actual SDK traffic: it responded, is past OOBE,
	/// and the certificate has a CN.
	///
	/// Use for path-selection decisions ("which URL should the SDK try?"). A probe that
	/// responded but is in maintenance / pre-OOBE is `hasResponded` but NOT `isOperational`.
	public var isOperational: Bool {
		guard let status, let about else { return false }
		return status.state == .ready
			&& status.OOBE.done
			&& about.certificate_common_name.isEmpty == false
	}
}
