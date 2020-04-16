//
//  ImageDisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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
import WebKit

class WebViewDisplayViewController: DisplayViewController {

	var webView: WKWebView?
	lazy var fullScreenGesture: UITapGestureRecognizer = {
		return UITapGestureRecognizer(target: self, action: #selector(self.tapToFullScreen))
	}()

	override func renderSpecificView(completion: @escaping (Bool) -> Void) {
		WebViewDisplayViewController.externalContentBlockingRuleList { (blockList, error) in
			guard error == nil, let source = self.source else {
				if let error = error {
					Log.error("Error adding external content blocking rule list: \(error)")
				}

				completion(false)

				return
			}

			if self.webView == nil {
				let configuration: WKWebViewConfiguration = WKWebViewConfiguration()

				configuration.preferences.javaScriptEnabled = true

				if blockList != nil {

					configuration.userContentController.add(blockList!)

					self.webView = WKWebView(frame: .zero, configuration: configuration)

					if let webView = self.webView {
						let layoutGuide = self.view.safeAreaLayoutGuide

						webView.scrollView.bouncesZoom = false
						webView.translatesAutoresizingMaskIntoConstraints = false
						self.view.addSubview(webView)

						NSLayoutConstraint.activate([
							webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
							webView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),
							webView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
							webView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor)
						])

						webView.loadFileURL(source, allowingReadAccessTo: source)

						self.fullScreenGesture.delegate = self
						webView.addGestureRecognizer(self.fullScreenGesture)
					}
				}
			} else {
				self.webView?.loadFileURL(source, allowingReadAccessTo: source)
			}

			completion(true)
		}
	}

	static func externalContentBlockingRuleList(completionHandler: @escaping (WKContentRuleList?, Error?) -> Void ) {
		let blockRules = """
     [{
         "trigger": {
             "url-filter": ".*"
         },
         "action": {
             "type": "block"
         }
     },
     {
         "action": {
             "type": "ignore-previous-rules"
         },
         "trigger": {
             "url-filter": "^file\\\\:.*"
         }

     },
     {
         "trigger": {
             "url-filter": "^x\\\\-apple.*\\\\:.*"
         },
         "action": {
             "type": "ignore-previous-rules"
         }
     }]
  """

		WKContentRuleListStore.default().compileContentRuleList(
			forIdentifier: "ContentBlockingRules",
			encodedContentRuleList: blockRules) { (contentRuleList, error) in
				completionHandler(contentRuleList, error)
		}
	}

	@objc func tapToFullScreen() {
		if let navigationController = self.parent?.navigationController {
			let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9) {
				navigationController.isNavigationBarHidden.toggle()
			}
			animator.startAnimation()
		}
	}
}

extension WebViewDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		do {
			if let mimeType = context.location?.identifier?.rawValue {
				let supportedFormatsRegex = try NSRegularExpression(pattern: "\\A((text/(html|css))|(image/gif)|(application/(javascript|json|x-php|octet-stream)))", options: .caseInsensitive)
				let matches = supportedFormatsRegex.numberOfMatches(in: mimeType, options: .reportCompletion, range: NSRange(location: 0, length: mimeType.count))

				if matches > 0 {
					return .locationMatch
				}
			}

			return .noMatch
		} catch {
			return .noMatch
		}
	}
	static var displayExtensionIdentifier: String = "org.owncloud.webview"
	static var supportedMimeTypes: [String]?
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}

extension WebViewDisplayViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if  otherGestureRecognizer == fullScreenGesture {
			return false
		}

		return true
	}
}
