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

typealias CompletionHandler = (() -> Void)

class OverlayPasscodeView: UIView {

    // MARK: - Overlay view
    @IBOutlet var logoTVGView : VectorImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func loadOverlay(isHidden: Bool, viewToShow: UIView) {
        Theme.shared.add(tvgResourceFor: "owncloud-logo")
        logoTVGView.vectorImage = Theme.shared.tvgImage(for: "owncloud-logo")
        self.isHidden = isHidden
    }

    func hide() {
        UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: {
            self.alpha = 0
        }, completion: { _ in
            self.isHidden = true
        })
    }

    func show() {

        self.isHidden = false

        UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: {
            self.alpha = 1
        }, completion: { _ in
        })
    }
}

class PasscodeViewController: UIViewController, Themeable {

    // MARK: - Overlay
    var hiddenOverlay: Bool?
    @IBOutlet var overlayPasscodeView: OverlayPasscodeView!

    // MARK: - Messages and input text
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var errorMessageLabel: UILabel?
    @IBOutlet weak var passcodeValueTextField: UITextField?
    @IBOutlet weak var timeTryAgainMessageLabel: UILabel?

    // MARK: - Buttons
    @IBOutlet var numberButtons: [ThemeButton]?
    @IBOutlet weak var cancelButton: ThemeButton?

    // MARK: - Initalization view
    init(hiddenOverlay: Bool) {
        super.init(nibName: "PasscodeViewController", bundle: nil)
        self.hiddenOverlay = hiddenOverlay
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

        self.view.addSubview(self.overlayPasscodeView)
        self.overlayPasscodeView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.overlayPasscodeView.loadOverlay(isHidden: self.hiddenOverlay!, viewToShow: self.view)

        self.cancelButton?.titleLabel?.text = "Cancel".localized

        self.setIdentifiers()
    }

    func setEnableNumberButtons(isEnable: Bool) {

        var alpha: CGFloat = 0.5

        if isEnable {
            alpha = 1.0
        }

        for button in self.numberButtons! {
            button.isEnabled = isEnable
            button.alpha = alpha
        }
    }

    // MARK: - Actions

    @IBAction func cancelButton(sender: UIButton) {
        PasscodeManager.shared.dismissPasscode(animated: true)
    }

    @IBAction func numberButton(sender: UIButton) {
        if let passcodeValue = self.passcodeValueTextField?.text {
            self.passcodeValueTextField?.text = passcodeValue + String(sender.tag)
        } else {
            self.passcodeValueTextField?.text = String(sender.tag)
        }

        self.passcodeValueChanged(passcodeValue: (self.passcodeValueTextField?.text)!)
    }

    // MARK: - Passcode Flow

    private func passcodeValueChanged(passcodeValue: String) {
        PasscodeManager.shared.passcodeValueHasChange(passcodeValue: passcodeValue)
    }

    // MARK: - Identifiers

    private func setIdentifiers() {

        self.overlayPasscodeView.accessibilityIdentifier = "overlayView"

        self.messageLabel?.accessibilityIdentifier = "messageLabel"
        self.errorMessageLabel?.accessibilityIdentifier = "errorMessageLabel"
        self.passcodeValueTextField?.accessibilityIdentifier = "passcodeValueTextField"
        self.timeTryAgainMessageLabel?.accessibilityIdentifier = "timeTryAgainMessageLabel"

        for button in self.numberButtons! {
            button.accessibilityIdentifier = "number" + String(button.tag) + "Button"
        }

        self.cancelButton?.accessibilityIdentifier = "cancelButton"
    }

    // MARK: - Themeing

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.view.backgroundColor = collection.tableBackgroundColor
        self.overlayPasscodeView.backgroundColor = collection.tableBackgroundColor

        self.messageLabel?.applyThemeCollection(collection, itemStyle: .bigTitle, itemState: .normal)
        self.errorMessageLabel?.applyThemeCollection(collection)
        self.passcodeValueTextField?.applyThemeCollection(collection, itemStyle: .message, itemState: .normal)
        self.timeTryAgainMessageLabel?.applyThemeCollection(collection)

        for button in self.numberButtons! {
            button.applyThemeCollection(collection, itemStyle: .neutral)
        }

        self.cancelButton?.applyThemeCollection(collection, itemStyle: .neutral)
    }
}
