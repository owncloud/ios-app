import Foundation
import ownCloudAppShared
import UIKit

#if targetEnvironment(simulator) && (arch(arm64) || arch(arm64_32))
// telemetry.xcframework ships x86_64/i386 simulator slices only (no arm64 simulator).
final class TelemetryAnalyticsTracker: AnalyticsTrackerType {
	init() {}

	func track(_ event: AnalyticsEvent) {}
}

#else
import telemetry

final class TelemetryAnalyticsTracker: AnalyticsTrackerType {
	private let client = TelemetryClient.client
	let requestType = "YourRequestTypeHere"

	init() {
		guard let clientID = UIDevice.current.identifierForVendor else {
			Log.error("[Analytics] Unable to get client ID")
			return
		}
		do {
			let dbPath = FileManager.default.applicationSupportDirectory.absoluteString
			let configuration: [String : Any] = [
				TelemetryConstants.TELEMETRY_DATABASE_DIRECTORY_PATH_TAG: dbPath
			]
			try client.setup(
				clientID: clientID,
				requestType: requestType,
				configuration: configuration
			)
		} catch {
			Log.error("[Analytics] Unable to setup Telemetry SDK. Underlying error \(error)")
		}
	}

	func track(_ event: AnalyticsEvent) {
		do {
			var payload: [String: Any] = [:]
			payload["activity_id"] = ""
			payload["timestamp"] = UInt(Date().timeIntervalSince1970 * 1000)
			guard let telemetryEvent = try TelemetryEvent(payload: payload) else {
				Log.error("[Analytics] Unable to create Telemetry Event. Empty after init.")
				return
			}
			client.sendEvent(event: telemetryEvent)
		} catch {
			Log.error("[Analytics] Error tracking event: \(String(describing: error))")
		}
	}
}

#endif
