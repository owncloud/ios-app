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

    private let passcodeLength = 4

    // MARK: - Messages and input text
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var errorMessageLabel: UILabel?
    @IBOutlet weak var passcodeValueTextField: UITextField?
    @IBOutlet weak var timeoutMessageLabel: UILabel?

    // MARK: - Buttons
    @IBOutlet var numberButtons: [ThemeButton]?
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

        self.cancelButton?.titleLabel?.text = "Cancel".localized
    }

    func enableNumberButtons(enabled: Bool) {

        var alpha: CGFloat = 0.5

        if enabled {
            alpha = 1.0
        }

        for button in self.numberButtons! {
            button.isEnabled = enabled
            button.alpha = alpha
        }
    }

    // MARK: - Actions

    @IBAction func cancel(sender: UIButton) {
        self.cancelHandler()
    }

    @IBAction func numberPressed(sender: UIButton) {
        if let passcodeValue = self.passcodeValueTextField?.text {
            self.passcodeValueTextField?.text = passcodeValue + String(sender.tag)
        } else {
            self.passcodeValueTextField?.text = String(sender.tag)
        }

        //Once passcode is complete
        if self.passcodeValueTextField?.text!.count == passcodeLength {
            self.passcodeCompleteHandler((self.passcodeValueTextField?.text)!)
        }
    }

    // MARK: - Themeing

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.view.backgroundColor = collection.tableBackgroundColor

        self.messageLabel?.applyThemeCollection(collection, itemStyle: .bigTitle, itemState: .normal)
        self.errorMessageLabel?.applyThemeCollection(collection)
        self.passcodeValueTextField?.applyThemeCollection(collection, itemStyle: .message, itemState: .normal)
        self.timeoutMessageLabel?.applyThemeCollection(collection)

        for button in self.numberButtons! {
            button.applyThemeCollection(collection, itemStyle: .neutral)
        }

        self.cancelButton?.applyThemeCollection(collection, itemStyle: .neutral)
    }
}
