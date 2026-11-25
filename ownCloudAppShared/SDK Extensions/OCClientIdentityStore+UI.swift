//
//  OCClientIdentityStore+UI.swift
//  ownCloudAppShared
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
import UniformTypeIdentifiers
import ownCloudSDK

public extension OCClientIdentityInfo {
	/// One-line description for display, f.ex. "alice – expires 1 Dec 2027"
	var displaySummary: String {
		var summary = subjectSummary.isEmpty ? OCLocalizedString("Client certificate", nil) : subjectSummary

		if let expiryDate {
			let formattedDate = DateFormatter.localizedString(from: expiryDate, dateStyle: .medium, timeStyle: .none)

			summary += " – " + (isExpired ? OCLocalizedFormat("expired {{date}}", ["date" : formattedDate]) : OCLocalizedFormat("expires {{date}}", ["date" : formattedDate]))
		}

		return summary
	}
}

public extension OCClientIdentityStore {
	/// Answers WKWebView authentication challenges with the stored client identity for the challenge's host. Returns false if the challenge wasn't handled.
	@discardableResult func handle(webViewChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Bool {
		if let credential = credential(for: challenge) {
			completionHandler(.useCredential, credential)
			return true
		}

		return false
	}

	static func localizedDescription(for error: Error) -> String {
		let nsError = error as NSError

		if nsError.domain == OCClientIdentityErrorDomain, let code = OCClientIdentityError(rawValue: nsError.code) {
			switch code {
				case .wrongPassword: return OCLocalizedString("The password for the certificate file is incorrect.", nil)
				case .invalidFile: return OCLocalizedString("The file could not be read as a PKCS#12 (.p12/.pfx) certificate file.", nil)
				case .noIdentity: return OCLocalizedString("The file does not contain a certificate together with its private key.", nil)
				case .invalidHost: return OCLocalizedString("Please enter a valid server URL first.", nil)
				case .keychain: return OCLocalizedString("The certificate could not be saved to the keychain.", nil)
				@unknown default: break
			}
		}

		return error.localizedDescription
	}
}

/// UI for importing, inspecting and removing the TLS client certificate (mTLS) used for a server host.
public class ClientCertificateManager: NSObject, UIDocumentPickerDelegate {
	public typealias ChangeHandler = () -> Void

	private static var activeManagers: [ClientCertificateManager] = []

	let host: String
	weak var hostViewController: UIViewController?
	let changeHandler: ChangeHandler?

	private init(host: String, hostViewController: UIViewController, changeHandler: ChangeHandler?) {
		self.host = host
		self.hostViewController = hostViewController
		self.changeHandler = changeHandler
		super.init()
	}

	/// Presents the certificate options for `host`: details of the installed certificate (if any), import/replace and remove.
	public static func present(for host: String?, on hostViewController: UIViewController, sourceView: UIView? = nil, changeHandler: ChangeHandler? = nil) {
		guard let host = OCClientIdentityStore.normalizedHost(host) else {
			let alert = ThemedAlertController(title: OCLocalizedString("Client certificate", nil), message: OCClientIdentityStore.localizedDescription(for: NSError(domain: OCClientIdentityErrorDomain, code: OCClientIdentityError.invalidHost.rawValue)), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default))
			hostViewController.present(alert, animated: true)
			return
		}

		let manager = ClientCertificateManager(host: host, hostViewController: hostViewController, changeHandler: changeHandler)
		manager.presentOptions(sourceView: sourceView)
	}

	func presentOptions(sourceView: UIView?) {
		let info = OCClientIdentityStore.shared.identityInfo(forHost: host)
		let message: String

		if let info {
			message = OCLocalizedFormat("Presented to {{host}} when the server requests a client certificate:\n{{summary}}", ["host" : host, "summary" : info.displaySummary])
		} else {
			message = OCLocalizedFormat("No client certificate is installed for {{host}}. Import a PKCS#12 (.p12/.pfx) file if the server or a reverse proxy in front of it requires one.", ["host" : host])
		}

		let sheet = ThemedAlertController(title: OCLocalizedString("Client certificate", nil), message: message, preferredStyle: (sourceView != nil) ? .actionSheet : .alert)

		sheet.addAction(UIAlertAction(title: (info != nil) ? OCLocalizedString("Replace certificate…", nil) : OCLocalizedString("Import certificate…", nil), style: .default, handler: { [self] _ in
			pickFile()
		}))

		if info != nil {
			sheet.addAction(UIAlertAction(title: OCLocalizedString("Remove certificate", nil), style: .destructive, handler: { [self] _ in
				OCClientIdentityStore.shared.removeIdentity(forHost: host)
				changeHandler?()
			}))
		}

		sheet.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel))

		if let popover = sheet.popoverPresentationController, let sourceView {
			popover.sourceView = sourceView
			popover.sourceRect = sourceView.bounds
		}

		hostViewController?.present(sheet, animated: true)
	}

	func pickFile() {
		var contentTypes: [UTType] = [ .pkcs12 ]

		if let pfxType = UTType(filenameExtension: "pfx"), !contentTypes.contains(pfxType) {
			contentTypes.append(pfxType)
		}

		let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
		picker.delegate = self
		picker.allowsMultipleSelection = false

		ClientCertificateManager.activeManagers.append(self) // Keep alive while the picker is shown
		hostViewController?.present(picker, animated: true)
	}

	private func finish() {
		ClientCertificateManager.activeManagers.removeAll(where: { $0 === self })
	}

	public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		finish()
	}

	public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first else {
			finish()
			return
		}

		let didAccess = url.startAccessingSecurityScopedResource()
		let data = try? Data(contentsOf: url)
		if didAccess {
			url.stopAccessingSecurityScopedResource()
		}
		try? FileManager.default.removeItem(at: url) // asCopy: the file is a private copy

		guard let data else {
			showError(NSError(domain: OCClientIdentityErrorDomain, code: OCClientIdentityError.invalidFile.rawValue))
			finish()
			return
		}

		askForPassword(data: data, fileName: url.lastPathComponent)
	}

	func askForPassword(data: Data, fileName: String) {
		let alert = ThemedAlertController(title: OCLocalizedString("Certificate password", nil), message: OCLocalizedFormat("Enter the password for {{file}}.", ["file" : fileName]), preferredStyle: .alert)

		alert.addTextField { textField in
			textField.isSecureTextEntry = true
			textField.textContentType = .password
			textField.placeholder = OCLocalizedString("Password", nil)
		}

		alert.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: { [self] _ in
			finish()
		}))

		alert.addAction(UIAlertAction(title: OCLocalizedString("Import", nil), style: .default, handler: { [self, weak alert] _ in
			let password = alert?.textFields?.first?.text ?? ""

			do {
				_ = try OCClientIdentityStore.shared.importPKCS12(data, password: password, forHost: host)
				changeHandler?()
				finish()
			} catch {
				showError(error, retry: ((error as NSError).code == OCClientIdentityError.wrongPassword.rawValue) ? { [self] in
					askForPassword(data: data, fileName: fileName)
				} : nil)
				if (error as NSError).code != OCClientIdentityError.wrongPassword.rawValue {
					finish()
				}
			}
		}))

		hostViewController?.present(alert, animated: true)
	}

	func showError(_ error: Error, retry: (() -> Void)? = nil) {
		let alert = ThemedAlertController(title: OCLocalizedString("Import failed", nil), message: OCClientIdentityStore.localizedDescription(for: error), preferredStyle: .alert)

		if let retry {
			alert.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: { [self] _ in finish() }))
			alert.addAction(UIAlertAction(title: OCLocalizedString("Try again", nil), style: .default, handler: { _ in retry() }))
		} else {
			alert.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default))
		}

		hostViewController?.present(alert, animated: true)
	}
}
