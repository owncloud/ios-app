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

typealias CancelHandler = (() -> Void)
typealias PasscodeCompleteHandler = ((_ passcode: String) -> Void)

class PasscodeViewController: UIViewController, Themeable {

    // MARK: - Passcode
    private let passcodeLength = 4
    var passcode: String?

    // MARK: - Messages and input text
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var errorMessageLabel: UILabel?
    @IBOutlet weak var passcodeLabel: UILabel?
    @IBOutlet weak var timeoutMessageLabel: UILabel?

    /*var message: String?
    var errorMessage: String?
    var timeoutMessage: String?*/

    // MARK: - Buttons
    @IBOutlet var keyboardButtons: [ThemeButton]?
    @IBOutlet weak var cancelButton: ThemeButton?

    // MARK: - Handlers
    var cancelHandler:CancelHandler
    var passcodeCompleteHandler:PasscodeCompleteHandler

    // MARK: - Initalization view
    init(cancelHandler: @escaping CancelHandler, passcodeCompleteHandler: @escaping PasscodeCompleteHandler) {
        self.cancelHandler = cancelHandler
        self.passcodeCompleteHandler = passcodeCompleteHandler
        super.init(nibName: "PasscodeViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return Theme.shared.activeCollection.statusBarStyle
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

        self.cancelButton?.setTitle("Cancel".localized, for: .normal)
    }

    // MARK: Updates UI

    func updateUI(message: String?, errorMessage: String?, timeoutMessage: String?, passcode: String?) {
        self.messageLabel?.text = message
        self.errorMessageLabel?.text = errorMessage
        self.timeoutMessageLabel?.text = timeoutMessage
        self.passcode = passcode

        if errorMessage != nil {
            self.errorMessageLabel?.shakeHorizontally()
        }

        self.updatePasscodeDots()
    }

    private func updatePasscodeDots() {
        let whiteDot = "\u{25E6}"
        let blackDot = "\u{2022}"

        var passcodeText = ""

        for index in 1...passcodeLength {
            if let passcode = self.passcode, passcode.count >= index {
                passcodeText += blackDot
            } else {
                passcodeText += whiteDot
            }
        }

        self.passcodeLabel?.text = passcodeText
    }

    func updateTimeoutMessage(timeoutMessage: String!) {
        self.timeoutMessageLabel?.text = timeoutMessage
    }

    func enableKeyboardButtons(enabled: Bool) {

        var alpha: CGFloat = 0.5

        if enabled {
            alpha = 1.0
        }

        for button in self.keyboardButtons! {
            button.isEnabled = enabled
            button.alpha = alpha
        }
    }

    // MARK: - Actions

    @IBAction func delete(sender: UIButton) {
        if self.passcode != nil, self.passcode!.count > 0 {
            self.passcode?.removeLast()
            self.updatePasscodeDots()
        }
    }

    @IBAction func cancel(sender: UIButton) {
        self.cancelHandler()
    }

    @IBAction func numberPressed(sender: UIButton) {

        let checkPasscode = {
            self.updatePasscodeDots()
            //Once passcode is complete
            if self.passcode!.count == self.passcodeLength {
                //Added a small delay to give feedback to the user when press the last number
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.passcodeCompleteHandler(self.passcode!)
                }
            }
        }

        if let passcode = self.passcode {
            //Protection to not add more during the delay
            if passcode.count < passcodeLength {
                self.passcode = passcode + String(sender.tag)
                checkPasscode()
            }
        } else {
            self.passcode = String(sender.tag)
            checkPasscode()
        }
    }

    // MARK: - Themeing

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.view.backgroundColor = collection.tableBackgroundColor

        self.messageLabel?.applyThemeCollection(collection, itemStyle: .title, itemState: .normal)
        self.errorMessageLabel?.applyThemeCollection(collection)
        self.passcodeLabel?.applyThemeCollection(collection, itemStyle: .bigTitle, itemState: .normal)
        self.timeoutMessageLabel?.applyThemeCollection(collection)

        for button in self.keyboardButtons! {
            button.applyThemeCollection(collection, itemStyle: .neutral)
        }

        self.cancelButton?.applyThemeCollection(collection, itemStyle: .neutral)
    }
}
