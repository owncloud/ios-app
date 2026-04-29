import Foundation
import ownCloudSDK

/// A device as known to the curator stack — a fusion of the remote-access record (if any),
/// the locally-discovered mDNS record (if any), and the most recent path probes.
public struct MergedDevice: Sendable, Codable {
	public let remoteDevice: RemoteDevice?
	public let localDevice: LocalDevice?
	public let pathProbes: [PathProbe]

	public init(
		remoteDevice: RemoteDevice?,
		localDevice: LocalDevice?,
		pathProbes: [PathProbe]
	) {
		self.remoteDevice = remoteDevice
		self.localDevice = localDevice
		self.pathProbes = pathProbes
	}

	public var certificateCommonName: String? {
		if let remoteDevice {
			return remoteDevice.certificateCommonName
		}
		if let localDevice {
			return localDevice.certificateCommonName
		}
		return nil
	}

	func asJSON() -> String? {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		encoder.dateEncodingStrategy = .iso8601

		do {
			let data = try encoder.encode(self)
			if let json = String(data: data, encoding: .utf8) {
				return json
			}
			return nil
		} catch {
			return nil
		}
	}
}
