//
//  PasscodeViewController.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

typealias PasscodeHandler = (() -> Void)

let numberDigitsPasscode = 4
let passcodeKeychainAccount = "passcode-keychain-account"
let passcodeKeychainPath = "passcode-keychain-path"

// MARK: - Interface view mode
enum PasscodeInterfaceMode {
    case addPasscodeFirstStep
    case addPasscodeSecondStep
    case unlockPasscode
    case unlockPasscodeError
    case deletePasscode
    case deletePasscodeError
    case addPasscodeFirstStepAfterErrorOnSecond
}

class PasscodeViewController: UIViewController, Themeable {

    // MARK: - Handler
    var handler: PasscodeHandler?

    // MARK: - Overlay
    var passcodeFromFirstStep: String?
    var passcodeMode: PasscodeInterfaceMode?
    var hiddenOverlay: Bool?

    // MARK: - Overlay view
    @IBOutlet var overlayView: UIView!
    @IBOutlet var logoTVGView : VectorImageView!

    // MARK: - Messages and input text
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var errorMessageLabel: UILabel?
    @IBOutlet weak var passcodeValueTextField: UITextField?

    // MARK: - Buttons
    @IBOutlet weak var number0Button: ThemeButton?
    @IBOutlet weak var number1Button: ThemeButton?
    @IBOutlet weak var number2Button: ThemeButton?
    @IBOutlet weak var number3Button: ThemeButton?
    @IBOutlet weak var number4Button: ThemeButton?
    @IBOutlet weak var number5Button: ThemeButton?
    @IBOutlet weak var number6Button: ThemeButton?
    @IBOutlet weak var number7Button: ThemeButton?
    @IBOutlet weak var number8Button: ThemeButton?
    @IBOutlet weak var number9Button: ThemeButton?

    @IBOutlet weak var cancelButton: ThemeButton?

    // MARK: - Initalization view
    init(mode: PasscodeInterfaceMode, hiddenOverlay: Bool?, handler: PasscodeHandler?) {
        super.init(nibName: "PasscodeViewController", bundle: nil)
        self.passcodeFromFirstStep = nil
        self.passcodeMode = mode
        self.hiddenOverlay = hiddenOverlay
        self.handler = handler
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Theme.shared.register(client: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Theme.shared.unregister(client: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadUI()
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }

    // MARK: - Rotation Control

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - User Interface

    private func loadUI() {

        //Overlay
        Theme.shared.add(tvgResourceFor: "owncloud-logo")
        logoTVGView.vectorImage = Theme.shared.tvgImage(for: "owncloud-logo")
        self.overlayView.isHidden = self.hiddenOverlay!

        self.cancelButton?.titleLabel?.text = "Cancel".localized

        self.setIdentifiers()

        self.updateUI()
    }

    private func updateUI() {

        var messageText : String?
        var errorText : String? = ""

        switch self.passcodeMode {
        case .addPasscodeFirstStep?:
            messageText = "Insert your code".localized

        case .addPasscodeSecondStep?:
            messageText = "Reinsert your code".localized

        case .unlockPasscode?:
            messageText = "Insert your code".localized
            self.cancelButton?.isHidden = true

        case .unlockPasscodeError?:
            messageText = "Insert your code".localized
            errorText = "Incorrect code".localized
            self.cancelButton?.isHidden = true

        case .deletePasscode?:
            messageText = "Delete code".localized

        case .deletePasscodeError?:
            messageText = "Delete code".localized
            errorText = "Incorrect code".localized

        case .addPasscodeFirstStepAfterErrorOnSecond?:
            messageText = "Insert your code".localized
            errorText = "The insterted codes are not the same".localized

        default:
            break
        }

        self.messageLabel?.text = messageText
        self.errorMessageLabel?.text = errorText
    }

    func hideOverlay() {
        UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: {
            self.overlayView.alpha = 0
        }, completion: { _ in
            self.overlayView.isHidden = true
        })
    }

    func showOverlay() {
        self.overlayView.isHidden = false
        UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: {
            self.overlayView.alpha = 1
        }, completion: { _ in
            self.overlayView.isHidden = false
        })
    }

    // MARK: - Actions

    @IBAction func cancelButton(sender: UIButton) {
        self.dismiss(animated: true, completion: self.handler!)
    }

    @IBAction func numberButton(sender: UIButton) {
        if let passcodeValue = self.passcodeValueTextField?.text {
            self.passcodeValueTextField?.text = passcodeValue + String(sender.tag)
        } else {
            self.passcodeValueTextField?.text = String(sender.tag)
        }

        self.passcodeValueHasChange(passcodeValue: (self.passcodeValueTextField?.text)!)
    }

    // MARK: - Passcode Flow

    private func passcodeValueHasChange(passcodeValue: String) {

        if passcodeValue.count >= numberDigitsPasscode {

            switch self.passcodeMode {
            case .addPasscodeFirstStep?, .addPasscodeFirstStepAfterErrorOnSecond?:
                self.passcodeMode = .addPasscodeSecondStep
                self.passcodeFromFirstStep = passcodeValue
                self.passcodeValueTextField?.text = nil
                self.updateUI()

            case .addPasscodeSecondStep?:
                if passcodeFromFirstStep == passcodeValue {
                    //Save to keychain
                    OCAppIdentity.shared().keychain.write(NSKeyedArchiver.archivedData(withRootObject: passcodeValue), toKeychainItemForAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.dismiss(animated: true, completion: self.handler!)
                } else {
                    self.passcodeMode = .addPasscodeFirstStepAfterErrorOnSecond
                    self.passcodeFromFirstStep = nil
                    self.passcodeValueTextField?.text = nil
                    self.updateUI()
                }

            case .unlockPasscode?, .unlockPasscodeError?:

                let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                let passcodeFromKeychain = NSKeyedUnarchiver.unarchiveObject(with: passcodeData!) as? String

                if passcodeValue == passcodeFromKeychain {
                    self.handler!()
                } else {
                    self.passcodeMode = .unlockPasscodeError
                    self.passcodeValueTextField?.text = nil
                    self.updateUI()
                }

            case .deletePasscode?, .deletePasscodeError?:

                let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                let passcodeFromKeychain = NSKeyedUnarchiver.unarchiveObject(with: passcodeData!) as? String

                if passcodeValue == passcodeFromKeychain {
                    OCAppIdentity.shared().keychain.removeItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    self.dismiss(animated: true, completion: self.handler!)
                } else {
                    self.passcodeMode = .deletePasscodeError
                    self.passcodeValueTextField?.text = nil
                    self.updateUI()
                }

            default:
                break
            }
        }
    }

    // MARK: - Identifiers

    private func setIdentifiers() {

        self.overlayView.accessibilityIdentifier = "overlayView"

        self.messageLabel?.accessibilityIdentifier = "messageLabel"
        self.errorMessageLabel?.accessibilityIdentifier = "errorMessageLabel"
        self.passcodeValueTextField?.accessibilityIdentifier = "passcodeValueTextField"

        self.number0Button?.accessibilityIdentifier = "number0Button"
        self.number1Button?.accessibilityIdentifier = "number1Button"
        self.number2Button?.accessibilityIdentifier = "number2Button"
        self.number3Button?.accessibilityIdentifier = "number3Button"
        self.number4Button?.accessibilityIdentifier = "number4Button"
        self.number5Button?.accessibilityIdentifier = "number5Button"
        self.number6Button?.accessibilityIdentifier = "number6Button"
        self.number7Button?.accessibilityIdentifier = "number7Button"
        self.number8Button?.accessibilityIdentifier = "number8Button"
        self.number9Button?.accessibilityIdentifier = "number9Button"

        self.cancelButton?.accessibilityIdentifier = "cancelButton"
    }

    // MARK: - Themeing

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.view.backgroundColor = collection.tableBackgroundColor
        self.overlayView.backgroundColor = collection.tableBackgroundColor

        self.messageLabel?.applyThemeCollection(collection, itemStyle: .bigTitle, itemState: .normal)
        self.errorMessageLabel?.applyThemeCollection(collection)
        self.passcodeValueTextField?.applyThemeCollection(collection, itemStyle: .message, itemState: .normal)

        self.number0Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number1Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number2Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number3Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number4Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number5Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number6Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number7Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number8Button?.applyThemeCollection(collection, itemStyle: .neutral)
        self.number9Button?.applyThemeCollection(collection, itemStyle: .neutral)

        self.cancelButton?.applyThemeCollection(collection, itemStyle: .neutral)
    }
}
