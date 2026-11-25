//
//  MutualTLSBrowserSession.swift
//  ownCloud
//

/*
 * Copyright (C) 2026, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import WebKit
import AuthenticationServices
import ownCloudSDK
import ownCloudAppShared

/// OAuth2 / OpenID Connect browser session backed by an in-app WKWebView.
///
/// ASWebAuthenticationSession runs in Safari's context and can't present client certificates provided by the app,
/// so the SDK uses this session instead whenever a client identity is stored for the authorization URL's host
/// (see `OCAuthenticationMethodOAuth2.mutualTLSBrowserSessionClass`).
class MutualTLSBrowserSession: OCAuthenticationBrowserSession, WKNavigationDelegate {
	private var webView: WKWebView?
	private var navigationController: UINavigationController?
	private var retainedSelf: MutualTLSBrowserSession?

	override func start() -> Bool {
		guard let presenter = presentingViewController else {
			Log.error("MutualTLSBrowserSession: no view controller to present from")
			return false
		}

		let configuration = WKWebViewConfiguration()
		configuration.websiteDataStore = .nonPersistent() // like an ephemeral ASWebAuthenticationSession

		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.navigationDelegate = self
		self.webView = webView

		let viewController = UIViewController()
		viewController.view = webView
		viewController.title = url.host
		viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction(handler: { [weak self] _ in
			self?.finish(callbackURL: nil, error: NSError(domain: ASWebAuthenticationSessionErrorDomain, code: ASWebAuthenticationSessionError.canceledLogin.rawValue))
		}))

		let navigationController = ThemeNavigationController(rootViewController: viewController)
		navigationController.isModalInPresentation = true
		self.navigationController = navigationController

		retainedSelf = self // keep alive while presented
		presenter.present(navigationController, animated: true)

		webView.load(URLRequest(url: url))

		return true
	}

	private var presentingViewController: UIViewController? {
		var viewController = hostViewController

		if viewController == nil {
			viewController = UIApplication.shared.connectedScenes
				.compactMap({ ($0 as? UIWindowScene)?.keyWindow })
				.first?.rootViewController
		}

		while let presented = viewController?.presentedViewController, !presented.isBeingDismissed {
			viewController = presented
		}

		return viewController
	}

	private func finish(callbackURL: URL?, error: Error?) {
		webView?.stopLoading()
		webView?.navigationDelegate = nil

		let complete = { [self] in
			completed(withCallbackURL: callbackURL, error: error)
			retainedSelf = nil
		}

		if let navigationController, navigationController.presentingViewController != nil {
			navigationController.dismiss(animated: true, completion: complete)
		} else {
			complete()
		}

		navigationController = nil
		webView = nil
	}

	// MARK: - WKNavigationDelegate
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if let requestURL = navigationAction.request.url, requestURL.scheme?.lowercased() == scheme.lowercased() {
			// Redirect to the app's callback URL: authorization finished
			decisionHandler(.cancel)
			finish(callbackURL: requestURL, error: nil)
			return
		}

		decisionHandler(.allow)
	}

	func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		if !OCClientIdentityStore.shared.handle(webViewChallenge: challenge, completionHandler: completionHandler) {
			completionHandler(.performDefaultHandling, nil)
		}
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		let nsError = error as NSError

		// Cancelled loads (incl. the callback URL redirect) and "frame load interrupted" are expected
		if (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) || (nsError.domain == "WebKitErrorDomain" && nsError.code == 102) {
			return
		}

		Log.error("MutualTLSBrowserSession: loading failed: \(error)")

		let alert = ThemedAlertController(title: OCLocalizedString("Login page could not be loaded", nil), message: error.localizedDescription, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: { [weak self] _ in
			self?.finish(callbackURL: nil, error: error)
		}))
		alert.addAction(UIAlertAction(title: OCLocalizedString("Retry", nil), style: .default, handler: { [weak self, weak webView] _ in
			if let self, let webView {
				webView.load(URLRequest(url: webView.url ?? self.url))
			}
		}))
		navigationController?.present(alert, animated: true)
	}
}
