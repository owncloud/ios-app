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

class WebViewDisplayViewController: UIViewController, DisplayViewProtocol {
	static var supportedMimeTypes: [String] =
		["image/jpeg",
		 "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
		 "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]

	var extensionIdentifier: String!

	var imageView: UIImageView!

	static var features: [String : Any]? = [FeatureKeys.canEdit : true, FeatureKeys.showImages : true]

	var source: URL!

	weak var editingDelegate: DisplayViewEditingDelegate?

	var webView: WKWebView?

	required init() {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		WebViewDisplayViewController.externalContentBlockingRuleList { (blockList, error) in
			guard error == nil else {
				print(error)
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
}
