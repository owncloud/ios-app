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

public enum PasscodeAction {
	case setup
	case delete

	var localizedDescription : String {
		switch self {
		case .setup: return "Enter code".localized
		case .delete: return "Delete code".localized
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

	public class var isPasscodeSecurityEnabled: Bool {
		get {
			if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
				return true
			} else {
				return AppLockManager.shared.lockEnabled
			}
		}
		set(newValue) {
			AppLockManager.shared.lockEnabled = newValue
		}
	}
	public class var isBiometricalSecurityEnabled: Bool {
		get {
			if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
				return true
			} else {
				return AppLockManager.shared.biometricalSecurityEnabled
			}
		}
		set(newValue) {
			AppLockManager.shared.biometricalSecurityEnabled = newValue
		}
	}

	public init(parentViewController:UIViewController, action:PasscodeAction = .setup, completion:PasscodeSetupCompletion? = nil) {
		self.parentViewController = parentViewController
		self.action = action
	}

	public func start() {

		passcodeViewController = PasscodeViewController(cancelHandler: { (passcodeViewController) in
			passcodeViewController.dismiss(animated: true) {
				self.completionHandler?(true)
			}
		}, completionHandler: { (passcodeViewController, passcode) in
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
			} else { // Setup
				if self.passcodeFromFirstStep == nil {
					// 1) Enter passcode
					self.passcodeFromFirstStep = passcode
					self.updateUI(with: "Repeat code".localized)
				} else {
					// 2) Confirm passcode
					if self.passcodeFromFirstStep == passcode {
						// Confirmed passcode matches the original ones -> save and lock the app
						self.lock(with: passcode)
						self.passcodeViewController?.dismiss(animated: true, completion: {
							self.completionHandler?(false)
						})
					} else {
						//Passcode is not the same
						self.updateUI(with: self.action.localizedDescription, errorMessage: "The entered codes are different".localized)
					}
					self.passcodeFromFirstStep = nil
				}
			}
		}, hasCancelButton: !AppLockManager.shared.isPasscodeEnforced)

		passcodeViewController?.message = self.action.localizedDescription
		if AppLockManager.shared.isPasscodeEnforced {
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
		})

		passcodeViewController?.message = self.action.localizedDescription
		parentViewController.present(passcodeViewController!, animated: true, completion: nil)
	}

	private func resetPasscode() {
		AppLockManager.shared.passcode = nil
		AppLockManager.shared.unlocked = false
		PasscodeSetupCoordinator.isPasscodeSecurityEnabled = false
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
