import UIKit

public enum HCIcon {
	public static var settings: UIImage? { sharedIcon("settings") }
	public static var arrowBack: UIImage? { sharedIcon("arrow-back") }
	public static var reset: UIImage? { sharedIcon("reset") }
	public static var device: UIImage? { sharedIcon("device-icon") }
	public static var logo: UIImage? { sharedIcon("files-logo") }
	public static var touchId: UIImage? { sharedIcon("touch-id") }
	public static var faceId: UIImage? { sharedIcon("face-id") }
	public static var deleteArrow: UIImage? { sharedIcon("delete-arrow") }
	public static var edit: UIImage? { sharedIcon("edit") }
	public static var delete: UIImage? { sharedIcon("delete") }

	private static func sharedIcon(_ name: String) -> UIImage? {
		UIImage(named: name, in: Bundle.sharedAppBundle, with: nil)
	}
}
