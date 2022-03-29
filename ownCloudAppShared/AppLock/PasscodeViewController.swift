//
//  PasscodeViewController.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 03/05/2018.
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
import ownCloudApp
import LocalAuthentication

public typealias PasscodeViewControllerCancelHandler = ((_ passcodeViewController: PasscodeViewController) -> Void)
public typealias PasscodeViewControllerBiometricalHandler = ((_ passcodeViewController: PasscodeViewController) -> Void)
public typealias PasscodeViewControllerCompletionHandler = ((_ passcodeViewController: PasscodeViewController, _ passcode: String) -> Void)

public class PasscodeViewController: UIViewController, Themeable {

	// MARK: - Constants
	fileprivate var passCodeCompletionDelay: TimeInterval = 0.1

	// MARK: - Views
	@IBOutlet private var messageLabel: UILabel?
	@IBOutlet private var errorMessageLabel: UILabel?
	@IBOutlet private var passcodeLabel: UILabel?
	@IBOutlet private var timeoutMessageLabel: UILabel?

	@IBOutlet private var lockscreenContainerView : UIView?
	@IBOutlet private var backgroundBlurView : UIVisualEffectView?

	@IBOutlet private var keypadContainerView : UIView?
	@IBOutlet private var keypadButtons: [ThemeRoundedButton]?
	@IBOutlet private var deleteButton: ThemeButton?
	@IBOutlet public var cancelButton: ThemeButton?
	@IBOutlet public var biometricalButton: ThemeButton?
	@IBOutlet public var biometricalImageView: UIImageView?
	@IBOutlet public var compactHeightPasscodeTextField: UITextField?

	// MARK: - Properties
	private var passcodeLength: Int

	public var passcode: String? {
		didSet {
			self.updatePasscodeDots()
		}
	}

	public var message: String? {
		didSet {
			self.messageLabel?.text = message ?? " "
		}
	}

	public var errorMessage: String? {
		didSet {
			self.errorMessageLabel?.text = errorMessage ?? " "

			if errorMessage != nil {
				self.passcodeLabel?.shakeHorizontally()
			}
		}
	}

	var timeoutMessage: String? {
		didSet {
			self.timeoutMessageLabel?.text = timeoutMessage ?? ""
		}
	}

	var screenBlurringEnabled : Bool {
		didSet {
			self.backgroundBlurView?.isHidden = !screenBlurringEnabled
			self.lockscreenContainerView?.isHidden = screenBlurringEnabled
		}
	}

	var keypadButtonsEnabled: Bool {
		didSet {
			if let buttons = self.keypadButtons {
				for button in buttons {
					button.isEnabled = keypadButtonsEnabled
					button.alpha = keypadButtonsEnabled ? 1.0 : (keypadButtonsHidden ? 1.0 : 0.5)
				}
			}

			self.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .update)
		}
	}

	var keypadButtonsHidden : Bool {
		didSet {
			keypadContainerView?.isUserInteractionEnabled = !keypadButtonsHidden

			if oldValue != keypadButtonsHidden {
				updateKeypadButtons()
			}
		}
	}

	var cancelButtonHidden: Bool {
		didSet {
			cancelButton?.isEnabled = cancelButtonHidden
			cancelButton?.isHidden = !cancelButtonHidden
		}
	}

	var biometricalButtonHidden: Bool = false {
		didSet {
			biometricalButton?.isEnabled = biometricalButtonHidden
			biometricalButton?.isHidden = !biometricalButtonHidden
			biometricalImageView?.isHidden = !biometricalButtonHidden
			biometricalImageView?.image = LAContext().biometricsAuthenticationImage()
		}
	}

	var hasCompactHeight: Bool {
		if self.traitCollection.verticalSizeClass == .compact {
			return true
		}

		return false
	}

	// MARK: - Handlers
	public var cancelHandler: PasscodeViewControllerCancelHandler?
	public var biometricalHandler: PasscodeViewControllerBiometricalHandler?
	public var completionHandler: PasscodeViewControllerCompletionHandler?

	// MARK: - Init
	public init(cancelHandler: PasscodeViewControllerCancelHandler? = nil, biometricalHandler: PasscodeViewControllerBiometricalHandler? = nil, completionHandler: @escaping PasscodeViewControllerCompletionHandler, hasCancelButton: Bool = true, keypadButtonsEnabled: Bool = true, requiredLength: Int) {
		self.cancelHandler = cancelHandler
		self.biometricalHandler = biometricalHandler
		self.completionHandler = completionHandler
		self.keypadButtonsEnabled = keypadButtonsEnabled
		self.cancelButtonHidden = hasCancelButton
		self.keypadButtonsHidden = false
		self.screenBlurringEnabled = false
		self.passcodeLength = requiredLength

		super.init(nibName: "PasscodeViewController", bundle: Bundle(for: PasscodeViewController.self))

		self.modalPresentationStyle = .fullScreen
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View Controller Events
	public override func viewDidLoad() {
		super.viewDidLoad()

		self.title = VendorServices.shared.appName
		self.cancelButton?.setTitle("Cancel".localized, for: .normal)

		self.message = { self.message }()
		self.errorMessage = { self.errorMessage }()
		self.timeoutMessage = { self.timeoutMessage }()

		self.cancelButtonHidden = { self.cancelButtonHidden }()
		self.keypadButtonsEnabled = { self.keypadButtonsEnabled }()
		self.keypadButtonsHidden = { self.keypadButtonsHidden }()
		self.screenBlurringEnabled = { self.screenBlurringEnabled }()
		self.errorMessageLabel?.minimumScaleFactor = 0.5
		self.errorMessageLabel?.adjustsFontSizeToFitWidth = true
		self.biometricalButtonHidden = !((!AppLockSettings.shared.biometricalSecurityEnabled || !AppLockSettings.shared.lockEnabled) || self.cancelButtonHidden)
		updateKeypadButtons()
        if let biometricalSecurityName = LAContext().supportedBiometricsAuthenticationName() {
            self.biometricalButton?.accessibilityLabel = biometricalSecurityName
        }

		if #available(iOS 13.4, *) {
			for button in keypadButtons! {
				PointerEffect.install(on: button, effectStyle: .highlight)
			}
			PointerEffect.install(on: cancelButton!, effectStyle: .highlight)
			PointerEffect.install(on: deleteButton!, effectStyle: .highlight)
			PointerEffect.install(on: biometricalButton!, effectStyle: .highlight)
		}
	}

	public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		self.keypadContainerView?.isHidden = true
		self.compactHeightPasscodeTextField?.resignFirstResponder()

		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: nil) { _ in
			self.updateKeypadButtons()
		}
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		Theme.shared.register(client: self)

		self.updatePasscodeDots()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		Theme.shared.unregister(client: self)
	}

	// MARK: - UI updates

	private func updateKeypadButtons() {
		if keypadButtonsHidden {
			self.compactHeightPasscodeTextField?.resignFirstResponder()
			UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
				self.keypadContainerView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
				self.keypadContainerView?.alpha = 0
			}, completion: { (_) in
				self.keypadContainerView?.isHidden = self.keypadButtonsHidden
			})
		} else {
			if !self.hasCompactHeight {
				self.keypadContainerView?.isHidden = self.keypadButtonsHidden
				self.compactHeightPasscodeTextField?.resignFirstResponder()

				UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
					self.keypadContainerView?.transform = .identity
					self.keypadContainerView?.alpha = 1
				}, completion: nil)
			} else {
				self.keypadContainerView?.isHidden = true
				self.compactHeightPasscodeTextField?.becomeFirstResponder()
			}
		}
	}

	private func updatePasscodeDots() {
		var placeholders = ""
		let enteredDigits = passcode?.count ?? 0

		for index in 1...passcodeLength {
			if index > 1 {
				placeholders += "  "
			}
			if index <= enteredDigits {
				placeholders += "●"
			} else {
				placeholders += "○"
			}
		}

		self.compactHeightPasscodeTextField?.text = passcode
		self.passcodeLabel?.text = placeholders
	}

	// MARK: - Actions
	@IBAction func appendDigit(_ sender: UIButton) {
		appendDigit(digit: String(sender.tag))
	}

	public func appendDigit(digit: String) {
		if !keypadButtonsEnabled || keypadButtonsHidden {
			return
		}

		if let currentPasscode = passcode {
			// Enforce length limit
			if currentPasscode.count < passcodeLength {
				self.passcode = currentPasscode + digit
			}
		} else {
			self.passcode = digit
		}

		// Check if passcode is complete
		if let enteredPasscode = passcode {
			if enteredPasscode.count == passcodeLength {
				// Delay to give feedback to user after the last digit was added
				OnMainThread(after: passCodeCompletionDelay) {
					self.completionHandler?(self, enteredPasscode)
				}
			}
		}
	}

	@IBAction func deleteLastDigit(_ sender: UIButton) {
		deleteLastDigit()
	}

	public func deleteLastDigit() {
		if passcode != nil, passcode!.count > 0 {
			passcode?.removeLast()
			updatePasscodeDots()
		}
	}

	@IBAction func cancel(_ sender: UIButton) {
		cancelHandler?(self)
	}

	@IBAction func biometricalAction(_ sender: UIButton) {
		biometricalHandler?(self)
	}

	// MARK: - Themeing
	public override var preferredStatusBarStyle : UIStatusBarStyle {
		if VendorServices.shared.isBranded {
			if #available(iOSApplicationExtension 13.0, *) {
				return .darkContent
			} else {
				return .default
			}
		}

		return Theme.shared.activeCollection.statusBarStyle
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

		lockscreenContainerView?.backgroundColor = collection.tableBackgroundColor

		messageLabel?.applyThemeCollection(collection, itemStyle: .title, itemState: keypadButtonsEnabled ? .normal : .disabled)
		errorMessageLabel?.applyThemeCollection(collection, itemStyle: .message, itemState: keypadButtonsEnabled ? .normal : .disabled)
		passcodeLabel?.applyThemeCollection(collection, itemStyle: .title, itemState: keypadButtonsEnabled ? .normal : .disabled)
		timeoutMessageLabel?.applyThemeCollection(collection, itemStyle: .message, itemState: keypadButtonsEnabled ? .normal : .disabled)

		for button in keypadButtons! {
			button.applyThemeCollection(collection, itemStyle: .bigTitle)
		}

		deleteButton?.themeColorCollection = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: collection.neutralColors.normal.background, background: .clear))

		biometricalImageView?.tintColor = collection.tintColor

		cancelButton?.applyThemeCollection(collection, itemStyle: .defaultForItem)
	}
}

extension PasscodeViewController: UITextFieldDelegate {
	open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

		if range.length > 0 {
			deleteLastDigit()
		} else {
			appendDigit(digit: string)
		}

		return false
	}
}
