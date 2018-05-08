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

enum PasscodeInterfaceMode {
    case addPasscodeFirstStep
    case addPasscodeSecondStep
    case unlockPasscode
    case unlockPasscodeError
    case deletePasscode
    case deletePasscodeError
    case addPasscodeFirstSetpAfterErrorOnSecond
}

class PasscodeViewController: UIViewController, Themeable {

    var handler: PasscodeHandler?

    var passcodeFromFirstStep: String?
    var passcodeMode: PasscodeInterfaceMode?
    var hiddenOverlay: Bool?

    @IBOutlet var overlayView: UIView!
    @IBOutlet var logoTVGView : VectorImageView!

    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var errorMessageLabel: UILabel?
    @IBOutlet weak var passcodeValueTextField: UITextField?

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

        switch self.passcodeMode {
        case .unlockPasscode?, .unlockPasscodeError?:

            if let dateData = UserDefaults.standard.data(forKey: DateHomeButtonPressedKey) {
                if let date = NSKeyedUnarchiver.unarchiveObject(with: dateData) as? Date {

                    let elapsed = Date().timeIntervalSince(date)
                    let secondsPassedMinToAsk = UserDefaults.standard.integer(forKey: SecuritySettingsfrequencyKey)

                    if Int(elapsed) < secondsPassedMinToAsk {
                        UserDefaults.standard.removeObject(forKey: DateHomeButtonPressedKey)
                        self.handler!()
                    }
                }
            } else {
                PasscodeUtilities.sharedPasscodeUtilities.storeDateHomeButtonPressed()
            }

            self.hideOverly()
        default:
            break
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

        switch self.passcodeMode {
        case .addPasscodeFirstStep?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = ""

        case .addPasscodeSecondStep?:
            self.messageLabel?.text = "Reinsert your code".localized
            self.errorMessageLabel?.text = ""

        case .unlockPasscode?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = ""
            self.cancelButton?.isHidden = true

        case .unlockPasscodeError?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = "Incorrect code".localized
            self.cancelButton?.isHidden = true

        case .deletePasscode?:
            self.messageLabel?.text = "Delete code".localized
            self.errorMessageLabel?.text = ""

        case .deletePasscodeError?:
            self.messageLabel?.text = "Delete code".localized
            self.errorMessageLabel?.text = "Incorrect code".localized

        case .addPasscodeFirstSetpAfterErrorOnSecond?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = "The insterted codes are not the same".localized

        default:
            break
        }
    }

    func hideOverly() {
        UIView.animate(withDuration: 1.0, delay: 0.3, options: [], animations: {
            self.overlayView.alpha = 0
        }, completion: { _ in
            self.overlayView.isHidden = true
        })
    }

    // MARK: - Actions

    @IBAction func cancelButton(sender: UIButton) {
        self.handler!()
        self.dismiss(animated: true, completion: nil)
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
            case .addPasscodeFirstStep?, .addPasscodeFirstSetpAfterErrorOnSecond?:
                self.passcodeMode = .addPasscodeSecondStep
                self.passcodeFromFirstStep = passcodeValue
                self.passcodeValueTextField?.text = nil
                self.updateUI()

            case .addPasscodeSecondStep?:
                if passcodeFromFirstStep == passcodeValue {
                    //Save to keychain
                    OCAppIdentity.shared().keychain.write(NSKeyedArchiver.archivedData(withRootObject: passcodeValue), toKeychainItemForAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                    UserDefaults.standard.set(true, forKey: SecuritySettingsPasscodeKey)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.passcodeMode = .addPasscodeFirstSetpAfterErrorOnSecond
                    self.passcodeFromFirstStep = nil
                    self.passcodeValueTextField?.text = nil
                    self.updateUI()
                }

            case .unlockPasscode?, .unlockPasscodeError?:

                let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
                let passcodeFromKeychain = NSKeyedUnarchiver.unarchiveObject(with: passcodeData!) as? String

                if passcodeValue == passcodeFromKeychain {
                    self.handler!()
                    UserDefaults.standard.removeObject(forKey: DateHomeButtonPressedKey)
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
                    UserDefaults.standard.set(false, forKey: SecuritySettingsPasscodeKey)
                    UserDefaults.standard.removeObject(forKey: DateHomeButtonPressedKey)
                    self.dismiss(animated: true, completion: nil)
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
