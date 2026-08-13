//
//  ClientWebAppViewController.swift
//  ownCloudAppShared
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
import ownCloudSDK
import WebKit

open class ClientWebAppViewController: UIViewController, WKUIDelegate {
	public typealias DoneHandler = (ClientWebAppViewController) -> Void

	public var urlRequest: URLRequest
	public var webView: WKWebView?

	public var shouldSendCloseEvent: Bool = true

	public var doneHandler: DoneHandler?

	public init(with urlRequest: URLRequest, doneHandler: DoneHandler? = nil) {
		self.urlRequest = urlRequest
		self.doneHandler = doneHandler

		super.init(nibName: nil, bundle: nil)

		self.isModalInPresentation = true
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public var webViewConfiguration: WKWebViewConfiguration {
		let configuration = WKWebViewConfiguration()
		let webSiteDataStore = WKWebsiteDataStore.nonPersistent()

		configuration.websiteDataStore = webSiteDataStore
		configuration.applicationNameForUserAgent = "MobileSafari" // Needed for some web apps that will present the desktop UI otherwise (f.ex. OnlyOffice as of 2022-09-19)

		return configuration
	}

	public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
		if navigationAction.targetFrame == nil, let url = navigationAction.request.url,
		   let openModeRaw = OpenInWebAppAction.classSetting(forOCClassSettingsKey: .inAppWebAppLinkOpenMode) as? String,
		   let openMode = InAppWebAppLinkOpenMode(rawValue: openModeRaw) {
			// Web app wants to open a link in a new window
			var title: String
			var openAction, navigateAction: UIAlertAction?

			title = OCLocalizedString("Web app requests to open link", nil)
			openAction = UIAlertAction(title: OCLocalizedString("Open", nil), style: .default) { (_) in
				OCAuthenticationBrowserSessionCustomScheme.open(url) // Open in default browser
			}
			navigateAction = UIAlertAction(title: OCLocalizedString("Navigate", nil), style: .default) { (_) in
				webView.load(navigationAction.request) // Navigate
			}

			switch openMode {
				case .withDefaultBrowser:
					navigateAction = nil

				case .navigate:
					openAction = nil

				case .choice:
					// allow all actions
					break

				case .deny:
					title = OCLocalizedString("The web app attempted to open the URL below. Opening was denied by configuration.", nil)
					openAction = nil
					navigateAction = nil

				case .silentDeny:
					Log.debug("ClientWebAppViewController denied opening a link.")
					return nil
			}

			let alert = ThemedAlertController(title: title, message: url.absoluteString, preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel)

			if let openAction {
				alert.addAction(openAction)
			}
			if let navigateAction {
				alert.addAction(navigateAction)
			}
			alert.addAction(cancelAction)

			present(alert, animated: true)
		}

		return nil // nil -> do not open; webView -> open in originating webView (default)
	}

	override public func loadView() {
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

	override public func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: OCSymbol.icon(forSymbolName: "xmark.circle.fill"), primaryAction: UIAction(handler: { [weak self] _ in
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

	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		webView?.load(urlRequest)
	}

	override public func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		// Drop web view
		webView?.uiDelegate = nil
		webView?.removeFromSuperview()
		webView = nil

		doneHandler?(self)
		doneHandler = nil
	}

	private var isDismissed = false
	public func dismissOnce(_ completion: (() -> Void)? = nil) {
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
	public func closeWebWindow() {
		webView?.evaluateJavaScript("window.close();")
	}

	// UI delegate
	public func webViewDidClose(_ webView: WKWebView) {
		dismissOnce({ [weak self] in
			self?.disposeWebViewOnce()
		})
	}
}
