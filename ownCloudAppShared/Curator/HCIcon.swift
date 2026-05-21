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
	public static var clearDark: UIImage? { sharedIcon("clear_dark") }
	public static var clearLight: UIImage? { sharedIcon("clear_light") }
	public static var errorIcon: UIImage? { sharedIcon("error_icon") }
	public static var tagIcon: UIImage? { sharedIcon("tag_icon") }

	private static func sharedIcon(_ name: String) -> UIImage? {
		UIImage(named: name, in: Bundle.sharedAppBundle, with: nil)
	}
}
