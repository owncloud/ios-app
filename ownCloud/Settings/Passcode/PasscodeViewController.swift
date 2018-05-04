//
//  PasscodeViewController.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

let numberDigitsPasscode = 4

enum PasscodeMode {
    case addPasscodeFirstStep
    case addPasscodeSecondStep
    case unlockPasscode
    case deletePasscode
    case addPasscodeFirstSetpAfterErrorOnSecond
}

class PasscodeViewController: UIViewController, Themeable {

    var passcodeFromFirstStep: String?
    var passcodeMode: PasscodeMode?

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

    init(mode: PasscodeMode, passcodeFromFirstStep: String?) {
        super.init(nibName: "PasscodeViewController", bundle: nil)
        self.passcodeFromFirstStep = passcodeFromFirstStep
        self.passcodeMode = mode
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
    }

    override func viewDidLoad() {
        self.loadInterface()

        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Interface

    func loadInterface() {

        //Top message
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

        case .deletePasscode?:
            self.messageLabel?.text = "Delete code".localized
            self.errorMessageLabel?.text = ""

        case .addPasscodeFirstSetpAfterErrorOnSecond?:
            self.messageLabel?.text = "Insert your code".localized
            self.errorMessageLabel?.text = "The insterted codes are not the same".localized

        default:
            break
        }
    }

    // MARK: - Actions

    @IBAction func cancelButton(sender: UIButton) {
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

    func passcodeValueHasChange(passcodeValue: String) {
        print(passcodeValue)

        if passcodeValue.count >= numberDigitsPasscode {

            switch self.passcodeMode {
            case .addPasscodeFirstStep?, .addPasscodeFirstSetpAfterErrorOnSecond?:
                self.passcodeMode = .addPasscodeSecondStep
                self.passcodeFromFirstStep = passcodeValue
                self.passcodeValueTextField?.text = nil
                self.loadInterface()

            case .addPasscodeSecondStep?:
                if passcodeFromFirstStep == passcodeValue {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.passcodeMode = .addPasscodeFirstSetpAfterErrorOnSecond
                    self.passcodeFromFirstStep = nil
                    self.passcodeValueTextField?.text = nil
                    self.loadInterface()
                }

            case .unlockPasscode?:
                self.dismiss(animated: true, completion: nil)

            case .deletePasscode?:
                self.dismiss(animated: true, completion: nil)

            default:
                break
            }
        }
    }

    // MARK: - Themeing

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.view.backgroundColor = collection.tableBackgroundColor

        self.messageLabel?.applyThemeCollection(collection, itemStyle: .bigTitle, itemState: .normal)
        self.errorMessageLabel?.applyThemeCollection(collection)
        self.passcodeValueTextField?.applyThemeCollection(collection, itemStyle: .message, itemState: .normal)

        self.number0Button?.themeColorCollection = collection.neutralColors
        self.number1Button?.themeColorCollection = collection.neutralColors
        self.number2Button?.themeColorCollection = collection.neutralColors
        self.number3Button?.themeColorCollection = collection.neutralColors
        self.number4Button?.themeColorCollection = collection.neutralColors
        self.number5Button?.themeColorCollection = collection.neutralColors
        self.number6Button?.themeColorCollection = collection.neutralColors
        self.number7Button?.themeColorCollection = collection.neutralColors
        self.number8Button?.themeColorCollection = collection.neutralColors
        self.number9Button?.themeColorCollection = collection.neutralColors

        self.cancelButton?.themeColorCollection = collection.neutralColors
    }
}
