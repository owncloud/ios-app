//
//  PasscodeSetupCoordinator.swift
//  ownCloud
//
//  Created by Michael Neuwert on 07.08.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudApp
import LocalAuthentication

public enum PasscodeAction {
	case setup
	case delete
	case upgrade

	var localizedDescription : String {
		switch self {
		case .setup: return "Enter code".localized
		case .delete: return "Delete code".localized
		case .upgrade: return String(format: "Enter a new code with %ld digits".localized, AppLockSettings.shared.requiredPasscodeDigits)
		}
	}
}

public class PasscodeSetupCoordinator {

	public typealias PasscodeSetupCompletion = (_ cancelled:Bool) -> Void

	private var parentViewController: UIViewController
	private var action: PasscodeAction

	private var passcodeViewController: PasscodeViewController?
	private var passcodeFromFirstStep: String?
	private var completionHandler: PasscodeSetupCompletion?
	private var minPasscodeDigits: Int {
		if AppLockSettings.shared.requiredPasscodeDigits > 4 {
			return AppLockSettings.shared.requiredPasscodeDigits
		}
		return 4
	}
	private var maxPasscodeDigits: Int {
		if AppLockSettings.shared.maximumPasscodeDigits < minPasscodeDigits {
			return minPasscodeDigits
		}
		return AppLockSettings.shared.maximumPasscodeDigits
	}

	public class var isPasscodeSecurityEnabled: Bool {
		get {
			if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
				return true
			} else {
				return AppLockSettings.shared.lockEnabled
			}
		}
		set(newValue) {
			AppLockSettings.shared.lockEnabled = newValue
		}
	}
	public class var isBiometricalSecurityEnabled: Bool {
		get {
			if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
				return true
			} else {
				return AppLockSettings.shared.biometricalSecurityEnabled
			}
		}
		set(newValue) {
			AppLockSettings.shared.biometricalSecurityEnabled = newValue
		}
	}

	public init(parentViewController:UIViewController, action:PasscodeAction = .setup, completion:PasscodeSetupCompletion? = nil) {
		self.parentViewController = parentViewController
		self.action = action
		self.completionHandler = completion
	}

	public func start() {
		if self.action == .setup, self.minPasscodeDigits < self.maxPasscodeDigits {
			showDigitsCountSelectionUI()
		} else {
			var requiredDigits = AppLockManager.shared.passcode?.count ?? AppLockSettings.shared.requiredPasscodeDigits
			if self.action == .upgrade {
				requiredDigits = AppLockSettings.shared.requiredPasscodeDigits
			}
			showPasscodeUI(requiredDigits: requiredDigits)
		}
	}

	public func showPasscodeUI(requiredDigits: Int) {
		passcodeViewController = PasscodeViewController(cancelHandler: { (passcodeViewController) in
			passcodeViewController.dismiss(animated: true) {
				self.completionHandler?(true)
			}
		}, completionHandler: { (_, passcode) in
			if self.action == .delete {
				if passcode == AppLockManager.shared.passcode {
					// Success -> Remove stored passcode and unlock the app
					self.resetPasscode()
					self.passcodeViewController?.dismiss(animated: true, completion: {
						self.completionHandler?(false)
					})
				} else {
					// Entered passcode doesn't match saved ones
					self.updateUI(with: self.action.localizedDescription, errorMessage: "Incorrect code".localized)
				}
			} else { // Setup or Upgrade
				if self.passcodeFromFirstStep == nil {
					// 1) Enter passcode
					self.passcodeFromFirstStep = passcode
					self.updateUI(with: "Repeat code".localized)
				} else {
					// 2) Confirm passcode
					if self.passcodeFromFirstStep == passcode {
						// Confirmed passcode matches the original ones -> save and lock the app
						self.lock(with: passcode)
						self.showSuggestBiometricalUnlockUI()
					} else {
						//Passcode is not the same
						self.updateUI(with: self.action.localizedDescription, errorMessage: "The entered codes are different".localized)
					}
					self.passcodeFromFirstStep = nil
				}
			}
		}, hasCancelButton: !(AppLockSettings.shared.isPasscodeEnforced || self.action == .upgrade), requiredLength: requiredDigits)

		passcodeViewController?.message = self.action.localizedDescription
		if AppLockSettings.shared.isPasscodeEnforced {
			passcodeViewController?.errorMessage = "You are required to set the passcode".localized
		}

		if parentViewController.presentedViewController != nil {
			parentViewController.dismiss(animated: false) { [weak self] in
				guard let passcodeController = self?.passcodeViewController else { return }
				self?.parentViewController.present(passcodeController, animated: false, completion: nil)
			}
		} else {
			parentViewController.present(passcodeViewController!, animated: true, completion: nil)
		}
	}

	public func showSuggestBiometricalUnlockUI() {
		if let biometricalSecurityName = LAContext().supportedBiometricsAuthenticationName() {
			if AppLockSettings.shared.biometricalSecurityEnabled {
				self.passcodeViewController?.dismiss(animated: true, completion: {
					self.completionHandler?(false)
				})
				if AppLockManager.supportedOnDevice {
					AppLockManager.shared.showLockscreenIfNeeded(setupMode: true)
				}
			} else {
				let alertController = UIAlertController(title: biometricalSecurityName, message: String(format:"Unlock using %@?".localized, biometricalSecurityName), preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: "Enable".localized, style: .default, handler: { _ in
					PasscodeSetupCoordinator.isBiometricalSecurityEnabled = true
					self.passcodeViewController?.dismiss(animated: true, completion: {
						self.completionHandler?(false)
					})
					if AppLockManager.supportedOnDevice {
						AppLockManager.shared.showLockscreenIfNeeded(setupMode: true)
					}
				}))

				alertController.addAction(UIAlertAction(title: "Disable".localized, style: .cancel, handler: { _ in
					PasscodeSetupCoordinator.isBiometricalSecurityEnabled = false
					self.passcodeViewController?.dismiss(animated: true, completion: {
						self.completionHandler?(false)
					})
				}))

				self.passcodeViewController?.present(alertController, animated: true, completion: {
				})
			}
		} else {
			self.passcodeViewController?.dismiss(animated: true, completion: {
				   self.completionHandler?(false)
			   })
		}
	}

	public func showDigitsCountSelectionUI() {
		let alertController = ThemedAlertController(title: "Passcode option".localized, message: "Please choose how many digits you want to use for the passcode lock?".localized, preferredStyle: .actionSheet)

		if let popoverController = alertController.popoverPresentationController {
			popoverController.sourceView = self.parentViewController.view
			popoverController.sourceRect = CGRect(x: self.parentViewController.view.bounds.midX, y: self.parentViewController.view.bounds.midY, width: 0, height: 0)
			popoverController.permittedArrowDirections = []
		}

		if !AppLockSettings.shared.isPasscodeEnforced {
			alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { _ in
				self.completionHandler?(true)
			}))
		}

		var digit = self.maxPasscodeDigits
		while digit >= self.minPasscodeDigits {
			let currentDigit = digit
				alertController.addAction(UIAlertAction(title: String(format: "%ld digit code".localized, currentDigit), style: .default, handler: { _ in
					self.showPasscodeUI(requiredDigits: currentDigit)
				}))
			digit -= 2
		}

		parentViewController.present(alertController, animated: true, completion: nil)
	}

	public func startBiometricalFlow(_ enable:Bool) {

		passcodeViewController = PasscodeViewController(cancelHandler: { (passcodeViewController: PasscodeViewController) in
				passcodeViewController.dismiss(animated: true) {
				self.completionHandler?(true)
			}
		}, completionHandler: { (passcodeViewController: PasscodeViewController, passcode: String) in
			if passcode == AppLockManager.shared.passcode {
				// Success
				passcodeViewController.dismiss(animated: true, completion: {
					self.completionHandler?(false)
					PasscodeSetupCoordinator.isBiometricalSecurityEnabled = enable
				})
			} else {
				// Error
				passcodeViewController.errorMessage = "Incorrect code".localized
				passcodeViewController.passcode = nil
			}
		}, requiredLength: AppLockManager.shared.passcode?.count ?? AppLockSettings.shared.requiredPasscodeDigits)

		passcodeViewController?.message = self.action.localizedDescription
		parentViewController.present(passcodeViewController!, animated: true, completion: nil)
	}

	private func resetPasscode() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.unlocked = false
		PasscodeSetupCoordinator.isPasscodeSecurityEnabled = false
		PasscodeSetupCoordinator.isBiometricalSecurityEnabled = false
	}

	private func lock(with passcode:String) {
		AppLockManager.shared.passcode = passcode
		AppLockManager.shared.unlocked = true
		PasscodeSetupCoordinator.isPasscodeSecurityEnabled = true
	}

	private func updateUI(with message:String, errorMessage:String? = nil) {
		self.passcodeViewController?.message = message
		if errorMessage != nil {
			self.passcodeViewController?.errorMessage = errorMessage
		}
		self.passcodeViewController?.passcode = nil
	}
}
