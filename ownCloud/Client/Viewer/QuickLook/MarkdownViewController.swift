//
//  PreviewViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK
import QuickLook
import ownCloudAppShared

class MarkdownViewController : DisplayViewController, UIGestureRecognizerDelegate {

	var overlayView : GestureView?

	override var isFullScreenModeEnabled: Bool {
		didSet {
			overlayView?.isHidden = !isFullScreenModeEnabled
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		supportsFullScreenMode = true
	}

	override func renderItem(completion: @escaping (Bool) -> Void) {
		if itemDirectURL != nil {
            
            let textView = UITextView(frame: .zero)
            textView.translatesAutoresizingMaskIntoConstraints = false
            

			overlayView = GestureView()
			overlayView?.isHidden = !isFullScreenModeEnabled

			view.addSubview(textView)

			NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
/*
				overlayView!.topAnchor.constraint(equalTo: view.topAnchor),
				overlayView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
				overlayView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				overlayView!.trailingAnchor.constraint(equalTo: view.trailingAnchor)
 */
			])

			let showHideBarsTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showHideBars))
			showHideBarsTapGestureRecognizer.delegate = self
			showHideBarsTapGestureRecognizer.numberOfTapsRequired = 1
		//	overlayView!.addGestureRecognizer(showHideBarsTapGestureRecognizer)
            
            do {
            let data = try Data(contentsOf: itemDirectURL!)
            
            if let stringEncoding = data.stringEncoding, let string = String(data: data, encoding: stringEncoding) {
                print(try string.toHTML())
                
                textView.attributedText = NSAttributedString(string.toMarkdown())
            }
                
            } catch {
                assertionFailure("Failed reading from URL: \(itemDirectURL), Error: " + error.localizedDescription)
            }

			completion(true)
		} else {
			completion(false)
		}
	}

	@objc func showHideBars() {
		guard let navigationController = navigationController else {
			return
		}

		if !navigationController.isNavigationBarHidden {
			navigationController.setNavigationBarHidden(true, animated: true)
		} else {
			navigationController.setNavigationBarHidden(false, animated: true)
		}
		overlayView?.isHidden = !navigationController.isNavigationBarHidden

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	// MARK: - Themeable implementation
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

	}
}
/*
// MARK: - GestureRecognizer delegate
extension MarkdownViewController: UIGestureRecognizerDelegate {
}*/

// MARK: - Display Extension.
extension MarkdownViewController: DisplayExtension {
	private static let supportedFormatsRegex = try? NSRegularExpression(pattern: "\\A(text/markdown)", options: .caseInsensitive)

	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in

		guard let regex = supportedFormatsRegex else { return .noMatch }

		if let mimeType = context.location?.identifier?.rawValue {

			let matches = regex.numberOfMatches(in: mimeType, options: .reportCompletion, range: NSRange(location: 0, length: mimeType.count))

			if matches > 0 {
				return .locationMatch
			}
		}

		return .noMatch
	}

	static var supportedMimeTypes: [String]?
	static var displayExtensionIdentifier: String = "org.owncloud.markdown"
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
