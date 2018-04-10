//
//  BookmarkViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program.
 * If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudUI

enum BookmarkViewControllerMode {
    case add
    case edit
}

let BookmarkDefaultURLKey = "default-url"
let BookmarkURLEditableKey = "url-editable"

class BookmarkViewController: StaticTableViewController, OCClassSettingsSupport {

    public var mode : BookmarkViewControllerMode!
    public var bookmark: OCBookmark?
    public var connection: OCConnection?
    private var authMethodType: OCAuthenticationMethodType?

    convenience init( mode: BookmarkViewControllerMode!, bookmark: OCBookmark?) {
        self.init(style: UITableViewStyle.grouped)

        self.mode = mode
        self.bookmark = bookmark
    }

    static func classSettingsIdentifier() -> String! {
        return "bookmark"
    }

    static func defaultSettings(forIdentifier identifier: String!) -> [String : Any]! {
        return [ BookmarkDefaultURLKey : "",
                 BookmarkURLEditableKey : true
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.bounces = false

            if let loginMode = self.mode {
                switch loginMode {
                case .add:
                    print("Add mode")
                    self.navigationItem.title = "Add Server".localized
                    self.addServerUrl()
                    self.addContinueButton(action: self.continueButtonAction)

                case .edit:
                    print("Edit mode")
                    self.navigationItem.title = "Edit Server".localized
                    self.addServerName()
                    self.addServerUrl()
                   // self.continueAction()
                    if let bookmark: OCBookmark = self.bookmark,
                        let authMethodID = bookmark.authenticationMethodIdentifier,
                        authMethodID == OCAuthenticationMethodBasicAuthIdentifier {

                        let username = OCAuthenticationMethodBasicAuth.userName(fromAuthenticationData: bookmark.authenticationData)
                        self.addBasicAuthCredentialsFields(username: username, password: "")
                    }
                    self.addConnectButton()
                    self.addDeleteAuthDataButton()
                    self.tableView.reloadData()
                }
            }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.textField?.becomeFirstResponder()
    }

    func updateBookmark(_ bookmark: OCBookmark) {
        BookmarkManager.sharedBookmarkManager.replaceBookmark(bookmark)

    }

    private func addServerUrl() {

        var serverURLName = self.classSetting(forOCClassSettingsKey: BookmarkDefaultURLKey) as? String ?? ""

        if let loginMode = self.mode {
            switch loginMode {
            case .add:
                break
            case .edit:
                if let url = self.bookmark?.url {
                    serverURLName = url.absoluteString
                }
            }
        }

        let serverURLSection: StaticTableViewSection = StaticTableViewSection(headerTitle:NSLocalizedString("Server URL", comment: ""), footerTitle: nil, identifier: "server-url-section")

        let serverURLRow: StaticTableViewRow = StaticTableViewRow(textFieldWithAction: nil,
                                                                  placeholder: NSLocalizedString("https://example.com", comment: ""),
                                                                  value: serverURLName,
                                                                  keyboardType: .default,
                                                                  autocorrectionType: .no,
                                                                  autocapitalizationType: .none,
                                                                  enablesReturnKeyAutomatically: false,
                                                                  returnKeyType: .continue,
                                                                  identifier: "server-url-textfield")
        serverURLRow.cell?.isUserInteractionEnabled = self.classSetting(forOCClassSettingsKey: BookmarkURLEditableKey) as? Bool ?? true

        serverURLSection.add(rows: [serverURLRow])
        addSection(serverURLSection, animated: false)
    }

    private func addContinueButton(action: @escaping StaticTableViewRowAction) {

        let continueButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "continue-button-section", rows: [
            StaticTableViewRow(buttonWithAction: action, title: NSLocalizedString("Continue", comment: ""),
               style: .proceed,
               identifier: "continue-button-row")
            ])

        self.addSection(continueButtonSection, animated: false)
    }

    private func addServerName() {

        var serverName = ""
        if let loginMode = self.mode {
            switch loginMode {
            case .add:
                break
            case .edit:
                if let name = self.bookmark?.name {
                    serverName = name
                }
            }
        }

        let section = StaticTableViewSection(headerTitle: NSLocalizedString("Name", comment: ""), footerTitle: nil, identifier: "server-name-section", rows: [
            StaticTableViewRow(textFieldWithAction: nil,
                               placeholder: NSLocalizedString("Example Server", comment: ""),
                               value: serverName,
                               secureTextEntry: false,
                               keyboardType: .default,
                               autocorrectionType: .yes, autocapitalizationType: .sentences, enablesReturnKeyAutomatically: true, returnKeyType: .done, identifier: "server-name-textfield")

            ])

        self.insertSection(section, at: 0, animated: true)
    }

    private func addCertificateDetails(certificate: OCCertificate) {
        let section =  StaticTableViewSection(headerTitle: NSLocalizedString("Certificate Details", comment: ""), footerTitle: nil)
        section.add(rows: [
            StaticTableViewRow(rowWithAction: {(staticRow, _) in
				staticRow.section?.viewController?.navigationController?.pushViewController(OCCertificateViewController.init(certificate: certificate), animated: true)
            }, title: NSLocalizedString("Show Certificate Details", comment: ""), accessoryType: .disclosureIndicator, identifier: "certificate-details-button")
        ])
        self.addSection(section, animated: true)
    }

    private func addConnectButton() {

        let connectButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "connect-button-section", rows: [
            StaticTableViewRow(buttonWithAction: { (row, _) in

                var options: [OCAuthenticationMethodKey : Any] = Dictionary()
                var method: String = OCAuthenticationMethodOAuth2Identifier

                if self.authMethodType != nil && self.authMethodType == OCAuthenticationMethodType.passphrase {

                    method = OCAuthenticationMethodBasicAuthIdentifier

                    let username: String? = self.sectionForIdentifier("passphrase-auth-section")?.row(withIdentifier: "passphrase-username-textfield-row")?.value as? String
                    let password: String?  = self.sectionForIdentifier("passphrase-auth-section")?.row(withIdentifier: "passphrase-password-textfield-row")?.value as? String

                    options[.usernameKey] = username!
                    options[.passphraseKey] = password!

                }

                options[.presentingViewControllerKey] = self

                let serverName = self.sectionForIdentifier("server-name-section")?.row(withIdentifier: "server-name-textfield")?.value as? String
                self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
                //TODO:refactor connection buttons and call update
                //self.updateBookmark(self.bookmark!)

                self.connection?.generateAuthenticationData(withMethod: method, options: options, completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in

                    if error == nil {
                        let serverName = self.sectionForIdentifier("server-name-section")?.row(withIdentifier: "server-name-textfield")?.value as? String
                        self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
                        self.bookmark?.authenticationMethodIdentifier = authenticationMethodIdentifier
                        self.bookmark?.authenticationData = authenticationData

                        if let loginMode = self.mode {
                            switch loginMode {
                            case .add:
                                BookmarkManager.sharedBookmarkManager.addBookmark(self.bookmark!)
                            case .edit:
                                BookmarkManager.sharedBookmarkManager.replaceBookmark(self.bookmark!)
                            }
                        }

                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let issuesVC = ConnectionIssueViewController(issue: OCConnectionIssue(forError: error, level: OCConnectionIssueLevel.error, issueHandler: nil))
                            issuesVC.modalPresentationStyle = .overCurrentContext
                            self.present(issuesVC, animated: true, completion: nil)
                        }
                    }
                })
            }, title: NSLocalizedString("Connect", comment: ""),
               style: .proceed,
               identifier: nil)])

        self.addSection(connectButtonSection)

    }

    private func addDeleteAuthDataButton() {
        if let section = self.sectionForIdentifier("connect-button-section") {
            section.add(rows: [
                StaticTableViewRow(buttonWithAction: { (_, _) in
                    if self.bookmark != nil {

                        BookmarkManager.sharedBookmarkManager.removeAuthDataOfBookmark(self.bookmark!)

                        //TODO: move to update rows
                        self.sectionForIdentifier("passphrase-auth-section")?.row(withIdentifier: "passphrase-username-textfield-row")?.value  = ""
                        self.sectionForIdentifier("passphrase-auth-section")?.row(withIdentifier: "passphrase-password-textfield-row")?.value  = ""
                        self.tableView.reloadData()
                    }

                }, title: NSLocalizedString("Delete Authentication Data", comment: ""), style: .destructive, identifier: "delete-auth-button")
                ])
        }
    }

    private func removeContinueButton() {
        if let buttonSection = self.sectionForIdentifier("continue-button-section") {
            self.removeSection(buttonSection)
        }
    }

    private func addBasicAuthCredentialsFields(username: String?, password: String?) {

        let section = StaticTableViewSection(headerTitle:NSLocalizedString("Authentication", comment: ""), footerTitle: nil, identifier: "passphrase-auth-section", rows:
            [ StaticTableViewRow(textFieldWithAction: nil,
                                 placeholder: NSLocalizedString("Username", comment: ""),
                                 value: username ?? "",
                                 secureTextEntry: false,
                                 keyboardType: .emailAddress,
                                 autocorrectionType: .no,
                                 autocapitalizationType: UITextAutocapitalizationType.none,
                                 enablesReturnKeyAutomatically: true,
                                 returnKeyType: .continue,
                                 identifier: "passphrase-username-textfield-row"),

              StaticTableViewRow(textFieldWithAction: nil, placeholder: NSLocalizedString("Password", comment: ""),
                                 value: password ?? "",
                                 secureTextEntry: true,
                                 keyboardType: .emailAddress,
                                 autocorrectionType: .no,
                                 autocapitalizationType: .none,
                                 enablesReturnKeyAutomatically: true,
                                 returnKeyType: .go,
                                 identifier: "passphrase-password-textfield-row")
            ])
        self.insertSection(section, at: self.sections.count-1, animated: true)
    }

    func continueAction() {

        var username: NSString?
        var password: NSString?
        var afterURL: String = ""

        afterURL = self.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.value as? String ?? ""

        var protocolAppended: ObjCBool = false

        if let bookmark: OCBookmark = OCBookmark(for: NSURL(username: &username, password: &password, afterNormalizingURLString: afterURL, protocolWasPrepended: &protocolAppended) as URL),
            let newConnection: OCConnection = OCConnection(bookmark: bookmark) {

            self.bookmark = bookmark
            self.connection = connection

            newConnection.prepareForSetup(options: nil, completionHandler: { (issuesFromSDK, _, _, preferredAuthMethods) in

                if let issues = issuesFromSDK?.issuesWithLevelGreaterThanOrEqual(to: OCConnectionIssueLevel.warning),
                    issues.count > 0 {
                    DispatchQueue.main.async {
                        let issuesVC = ConnectionIssueViewController(issue: issuesFromSDK!)
                        issuesVC.modalPresentationStyle = .overCurrentContext
                        self.present(issuesVC, animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.approveButtonAction(preferedAuthMethods: preferredAuthMethods!, issuesFromSDK: issuesFromSDK!, username: username as String?, password: password as String?)
                    }
                }
            })
        }
    }

    private var continueButtonAction: StaticTableViewRowAction  = { (row, _) in

        self.continueAction()

    }

    private func approveButtonAction(preferedAuthMethods: [String], issuesFromSDK: OCConnectionIssue?, username: String?, password: String?) {

        self.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.value = self.bookmark?.url.absoluteString

        if let preferedAuthMethod = preferedAuthMethods.first as String? {

            self.authMethodType = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: preferedAuthMethod).type()

            DispatchQueue.main.async {
                self.addServerName()
                if let certificateIssue = issuesFromSDK?.issues.filter({ $0.type == .certificate}).first {
                    self.addCertificateDetails(certificate: certificateIssue.certificate)
                }

                if self.authMethodType == .passphrase {
                    self.addBasicAuthCredentialsFields(username: username, password:password)
                }
                self.removeContinueButton()
                self.addConnectButton()
                self.tableView.reloadData()
            }
        }
    }
}
