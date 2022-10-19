//
//  ClientWebAppViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 19.09.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import WebKit
import ownCloudAppShared

class ClientWebAppViewController: UIViewController, WKUIDelegate {
	var urlRequest: URLRequest
	var webView: WKWebView?

	var shouldSendCloseEvent: Bool = true

	init(with urlRequest: URLRequest) {
		self.urlRequest = urlRequest

		super.init(nibName: nil, bundle: nil)

		self.isModalInPresentation = true
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var webViewConfiguration: WKWebViewConfiguration {
		let configuration = WKWebViewConfiguration()
		let webSiteDataStore = WKWebsiteDataStore.nonPersistent()

		configuration.websiteDataStore = webSiteDataStore
		configuration.applicationNameForUserAgent = "MobileSafari" // Needed for some web apps that will present the desktop UI otherwise (f.ex. OnlyOffice as of 2022-09-19)

		return configuration
	}

	override func loadView() {
		let rootView = UIView()

		webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
		webView?.translatesAutoresizingMaskIntoConstraints = false
		webView?.uiDelegate = self

		rootView.addSubview(webView!)

		NSLayoutConstraint.activate([
			webView!.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor),
			webView!.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor),
			webView!.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor),
			webView!.bottomAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.bottomAnchor)
		])

		view = rootView
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate), primaryAction: UIAction(handler: { [weak self] _ in
			if self?.shouldSendCloseEvent == true {
				if let strongSelf = self {
					// Close via window.close(), which is calling dismissSecurely() once done
					strongSelf.closeWebWindow()

					// Call dismissOnce()
					strongSelf.dismissOnce({
						// Dispose after 10 seconds automatically (or earlier if web view signals close event)
						OnMainThread(after: 10) {
							strongSelf.disposeWebViewOnce()
						}
					})
				}
			} else {
				// Close directly
				self?.dismissOnce({ [weak self] in
					self?.disposeWebViewOnce()
				})
			}
		}))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		webView?.load(urlRequest)
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		// Drop web view
		webView?.uiDelegate = nil
		webView?.removeFromSuperview()
		webView = nil
	}

	private var isDismissed = false
	func dismissOnce(_ completion: (() -> Void)? = nil) {
		if !isDismissed {
			isDismissed = true
			self.dismiss(animated: true, completion: completion)
		} else {
			completion?()
		}
	}

	private var hasDisposedWebView = false
	func disposeWebViewOnce() {
		if !hasDisposedWebView {
			hasDisposedWebView = true
			webView?.removeFromSuperview()
			webView = nil
		}
	}

	// window.close() handling
	func closeWebWindow() {
		webView?.evaluateJavaScript("window.close();")
	}

	// UI delegate
	func webViewDidClose(_ webView: WKWebView) {
		dismissOnce({ [weak self] in
			self?.disposeWebViewOnce()
		})
	}
}
