import Foundation
import ownCloudSDK

/// Single typed channel for everything `DeviceReachabilityService` emits.
public enum DeviceReachabilityEvent: Sendable {
	/// The merged-device map changed (discovery, probes, mDNS, manual reset, …).
	case devicesUpdated([MergedDevice])
	/// A full Algorithm A detection pass finished; payload is the final merged map.
	case detectionComplete([MergedDevice])
	/// A remote (RA) device was discovered during the remote phase. Raw `RemoteDevice`,
	/// no local mDNS fields merged in.
	case remoteDeviceFound(RemoteDevice)
	/// An mDNS device whose `about` endpoint just got validated.
	case localDeviceFound(MergedDevice)
	/// `NetworkState.isReachable` changed.
	case reachabilityChanged(Bool)
	/// RA tokens are missing/invalid; the UI should drive the email-verification flow.
	case emailValidationNeeded(email: String)
	/// The remote base URL for the favorite device changed.
	case remoteBaseURLChanged(URL?)
}
