//
//  ImageDisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import WebKit

class WebViewDisplayViewController: DisplayViewController, DisplayViewProtocol {
	static var supportedMimeTypes: [String] =
		["image/jpeg",
		 "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
		 "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]

	static var features: [String : Any]? = [FeatureKeys.canEdit : true]

	static func webViewExtension(identifier: String) -> OCExtension {
		let rawIdentifier: OCExtensionIdentifier =  OCExtensionIdentifier(rawValue: identifier)
		var locationIdentifiers: [OCExtensionLocationIdentifier] = []
		for mimeType in supportedMimeTypes {
			let locationIdentifier: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier(rawValue: mimeType)
			locationIdentifiers.append(locationIdentifier)
		}

		let features: [String : Any] = WebViewDisplayViewController.features!

		let webViewExtension = OCExtension(identifier: rawIdentifier, type: .viewer, locations: locationIdentifiers, features: features) { (_ rawExtension, _ context, _ error) -> Any? in
			return WebViewDisplayViewController()
		}

		return webViewExtension!
	}

	var webView: WKWebView?

	override func renderSpecificView() {
		WebViewDisplayViewController.externalContentBlockingRuleList { (blockList, error) in
			guard error == nil else {
				print(error!)
				return
			}

			let configuration: WKWebViewConfiguration = WKWebViewConfiguration()

			configuration.preferences.javaScriptEnabled = true

			if blockList != nil {

				configuration.userContentController.add(blockList!)

				self.webView = WKWebView(frame: .zero, configuration: configuration)
				self.webView?.translatesAutoresizingMaskIntoConstraints = false
				self.view.addSubview(self.webView!)

				NSLayoutConstraint.activate([
					self.webView!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
					self.webView!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
					self.webView!.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
					self.webView!.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor)
					])

				self.webView?.loadFileURL(self.source, allowingReadAccessTo: self.source)

				let fullScreenGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapToFullScreen))
				fullScreenGesture.delegate = self
				self.webView?.addGestureRecognizer(fullScreenGesture)
			}
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
				navigationController.tabBarController?.tabBar.isHidden.toggle()
				self.webView?.isOpaque.toggle()
			}
			animator.startAnimation()
		}
	}
}

extension WebViewDisplayViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}
