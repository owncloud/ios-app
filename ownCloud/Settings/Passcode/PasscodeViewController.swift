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

typealias PasscodeViewControllerCancelHandler = ((_ passcodeViewController: PasscodeViewController) -> Void)
typealias PasscodeViewControllerCompletionHandler = ((_ passcodeViewController: PasscodeViewController, _ passcode: String) -> Void)

class PasscodeViewController: UIViewController, Themeable {

	// MARK: - Constants
	fileprivate var passCodeCompletionDelay: TimeInterval = 0.1
	fileprivate let inputDelete: String = "\u{8}"

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
	@IBOutlet private var cancelButton: ThemeButton?

	// MARK: - Properties
	var passcodeLength: Int = 4

	var passcode: String? {
		didSet {
			self.updatePasscodeDots()
		}
	}

	var message: String? {
		didSet {
			self.messageLabel?.text = message ?? " "
		}
	}

	var errorMessage: String? {
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
				if keypadButtonsHidden {
					UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
						self.keypadContainerView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
						self.keypadContainerView?.alpha = 0
					}, completion: { (_) in
						self.keypadContainerView?.isHidden = self.keypadButtonsHidden
					})
				} else {
					self.keypadContainerView?.isHidden = self.keypadButtonsHidden

					UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
						self.keypadContainerView?.transform = .identity
						self.keypadContainerView?.alpha = 1
					}, completion: nil)
				}
			}
		}
	}

	var cancelButtonHidden: Bool {
		didSet {
			cancelButton?.isEnabled = cancelButtonHidden
			cancelButton?.isHidden = !cancelButtonHidden
		}
	}

	// MARK: - Handlers
	var cancelHandler: PasscodeViewControllerCancelHandler?
	var completionHandler: PasscodeViewControllerCompletionHandler?

	// MARK: - Init
	init(cancelHandler: PasscodeViewControllerCancelHandler? = nil, completionHandler: @escaping PasscodeViewControllerCompletionHandler, hasCancelButton: Bool = true, keypadButtonsEnabled: Bool = true) {
		self.cancelHandler = cancelHandler
		self.completionHandler = completionHandler
		self.keypadButtonsEnabled = keypadButtonsEnabled
		self.cancelButtonHidden = hasCancelButton
		self.keypadButtonsHidden = false
		self.screenBlurringEnabled = false

		super.init(nibName: "PasscodeViewController", bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View Controller Events
	override func viewDidLoad() {
		super.viewDidLoad()

		self.cancelButton?.setTitle("Cancel".localized, for: .normal)

		self.message = { self.message }()
		self.errorMessage = { self.errorMessage }()
		self.timeoutMessage = { self.timeoutMessage }()

		self.cancelButtonHidden = { self.cancelButtonHidden }()
		self.keypadButtonsEnabled = { self.keypadButtonsEnabled }()
		self.keypadButtonsHidden = { self.keypadButtonsHidden }()
		self.screenBlurringEnabled = { self.screenBlurringEnabled }()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		Theme.shared.register(client: self)

		self.updatePasscodeDots()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		Theme.shared.unregister(client: self)
	}

	// MARK: - Orientation
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return .portrait
	}

	// MARK: - UI updates
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

		self.passcodeLabel?.text = placeholders
	}

	// MARK: - Actions
	@IBAction func appendDigit(_ sender: UIButton) {
        appendDigit(digit: String(sender.tag))
	}

    private func appendDigit(digit: String) {
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

    private func deleteLastDigit() {
        if passcode != nil, passcode!.count > 0 {
            passcode?.removeLast()
            updatePasscodeDots()
        }
    }

	@IBAction func cancel(_ sender: UIButton) {
		cancelHandler?(self)
	}

	// MARK: - Themeing
	override var preferredStatusBarStyle : UIStatusBarStyle {
		return Theme.shared.activeCollection.statusBarStyle
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

		lockscreenContainerView?.backgroundColor = collection.tableBackgroundColor

		messageLabel?.applyThemeCollection(collection, itemStyle: .title, itemState: keypadButtonsEnabled ? .normal : .disabled)
		errorMessageLabel?.applyThemeCollection(collection, itemStyle: .message, itemState: keypadButtonsEnabled ? .normal : .disabled)
		passcodeLabel?.applyThemeCollection(collection, itemStyle: .title, itemState: keypadButtonsEnabled ? .normal : .disabled)
		timeoutMessageLabel?.applyThemeCollection(collection, itemStyle: .message, itemState: keypadButtonsEnabled ? .normal : .disabled)

		for button in keypadButtons! {
			button.applyThemeCollection(collection, itemStyle: .bigTitle)
		}

		deleteButton?.themeColorCollection = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: collection.tintColor, background: collection.tableBackgroundColor))

		cancelButton?.applyThemeCollection(collection, itemStyle: .defaultForItem)
		cancelButton?.layer.cornerRadius = 0
	}

    // MARK: - External Keyboard Commands

    @objc func performKeyCommand(sender: UIKeyCommand) {
        guard let key = sender.input else {
            return
        }

        switch key {
        case inputDelete:
            deleteLastDigit()
        case UIKeyCommand.inputEscape:
            cancelHandler?(self)
        default:
            appendDigit(digit: key)
        }

    }

    override var keyCommands: [UIKeyCommand]? {

        var keyCommands : [UIKeyCommand] = []
        for i in 0 ..< 10 {
            keyCommands.append(
                UIKeyCommand(input:String(i),
                             modifierFlags: [],
                             action: #selector(self.performKeyCommand(sender:)),
                             discoverabilityTitle: String(i))
            )
        }

        keyCommands.append(
            UIKeyCommand(input: inputDelete,
                         modifierFlags: [],
                         action: #selector(self.performKeyCommand(sender:)),
                         discoverabilityTitle: "Delete".localized)
        )

        if cancelButton?.isHidden == false {
            keyCommands.append(

                UIKeyCommand(input: UIKeyCommand.inputEscape,
                            modifierFlags: [],
                            action: #selector(self.performKeyCommand(sender:)),
                            discoverabilityTitle: "Cancel".localized)
            )
        }

        return keyCommands
    }
}
