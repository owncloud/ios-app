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
	static var supportedMimeTypes: [String] = ["image/jpeg"]

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

		webView = WKWebView()
		webView?.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(webView!)

		NSLayoutConstraint.activate([
			webView!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
			webView!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
			webView!.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
			webView!.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor)
		])

		let configuration: WKWebViewConfiguration = WKWebViewConfiguration()

		WebViewDisplayViewController.externalContentBlockingRuleList { (blockList, error) in
			guard error == nil else {
				print(error)
				return
			}

			configuration.preferences.javaScriptEnabled = true

			if blockList != nil {
				configuration.userContentController.add(blockList!)
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
