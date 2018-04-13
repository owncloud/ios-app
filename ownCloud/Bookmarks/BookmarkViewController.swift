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

let BookmarkDefaultURLKey = "default-url"
let BookmarkURLEditableKey = "url-editable"

//Sections constants
let serverURLSectionIdentifier = "server-url-section"
let serverURLTextFieldIdentifier = "server-url-textfield"

let continueButtonRowIdentifier = "continue-button-row"
let continueButtonSectionIdentifier = "continue-button-section"

let serverNameSectionIdentifier = "server-name-section"
let serverNameTextFieldIdentifier = "server-name-textfield"

let passphraseUsernameRowIdentifier = "passphrase-username-textfield-row"
let passphrasePasswordIdentifier = "passphrase-password-textfield-row"
let passphraseAuthSectionIdentifier = "passphrase-auth-section"

let deleteAuthButtonIdentifier = "delete-auth-button"

let certificateDetailsButtonIdentifier = "certificate-details-button"

let connectButtonSectionIdentifier = "connect-button-section"


enum BookmarkViewControllerMode {
    case add
    case edit
}

class BookmarkViewController: StaticTableViewController, OCClassSettingsSupport {

    public var bookmark: OCBookmark?
    public var connection: OCConnection?
    private var authMethodType: OCAuthenticationMethodType?
    private var mode: BookmarkViewControllerMode?

    convenience init(bookmark: OCBookmark? = nil) {

        self.init(style: UITableViewStyle.grouped)

        self.bookmark = bookmark

        if bookmark == nil {
            self.mode = .add
        } else {
            self.mode = .edit
        }
    }

    static func classSettingsIdentifier() -> String! {
        return ClassSettingsIdentifiers.bookmarks
    }

    static func defaultSettings(forIdentifier identifier: String!) -> [String : Any]! {
        return [ BookmarkDefaultURLKey : "",
                 BookmarkURLEditableKey : true
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.bounces = false
        self.loadInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.textField?.becomeFirstResponder()
    }

    private func loadInterface() {

        switch self.mode {
        case .add?:
            self.navigationItem.title = "Add Server".localized
            self.addServerUrl()
            self.addContinueButton(action: self.continueButtonAction)
        case .edit?:
            self.navigationItem.title = "Edit Server".localized
            self.addServerName()
            self.addServerUrl()
            if self.bookmark?.authenticationMethodIdentifier == OCAuthenticationMethodBasicAuthIdentifier {
                let username = OCAuthenticationMethodBasicAuth.userName(fromAuthenticationData: self.bookmark?.authenticationData)
                self.addBasicAuthCredentialsFields(username: username, password: "")
            }
            //TODO: not working, the certificate is nil
            //self.addCertificateDetails(certificate: self.bookmark!.certificate)
            self.addConnectButton()
            self.addDeleteAuthDataButton()
            self.tableView.reloadData()
        default: break
        }

    }

    // MARK: Interface sections

    private func addServerUrl() {

        var serverURLName = self.classSetting(forOCClassSettingsKey: BookmarkDefaultURLKey) as? String ?? ""

        if let url = self.bookmark?.url {
            serverURLName = url.absoluteString
        }

        let serverURLSection: StaticTableViewSection = StaticTableViewSection(headerTitle:"Server URL".localized, footerTitle: nil, identifier: serverURLSectionIdentifier)

        let serverURLRow: StaticTableViewRow = StaticTableViewRow(textFieldWithAction: nil,
                                                                  placeholder: "https://example.com".localized,
                                                                  value: serverURLName,
                                                                  keyboardType: .default,
                                                                  autocorrectionType: .no,
                                                                  autocapitalizationType: .none,
                                                                  enablesReturnKeyAutomatically: false,
                                                                  returnKeyType: .continue,
                                                                  identifier: serverURLTextFieldIdentifier)
        serverURLRow.cell?.isUserInteractionEnabled = self.classSetting(forOCClassSettingsKey: BookmarkURLEditableKey) as? Bool ?? true

        serverURLSection.add(rows: [serverURLRow])
        addSection(serverURLSection, animated: false)
    }

    private func addContinueButton(action: @escaping StaticTableViewRowAction) {

        let continueButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: continueButtonSectionIdentifier, rows: [
            StaticTableViewRow(buttonWithAction: action, title: "Continue".localized,
               style: .proceed,
               identifier: continueButtonRowIdentifier)
            ])

        self.addSection(continueButtonSection, animated: false)
    }

    private func addServerName() {

        var serverName = ""

        if let name = self.bookmark?.name {
            serverName = name
        }

        let section = StaticTableViewSection(headerTitle: "Name".localized, footerTitle: nil, identifier: serverNameSectionIdentifier, rows: [
            StaticTableViewRow(textFieldWithAction: nil,
                               placeholder: "Example Server".localized,
                               value: serverName,
                               secureTextEntry: false,
                               keyboardType: .default,
                               autocorrectionType: .yes, autocapitalizationType: .sentences, enablesReturnKeyAutomatically: true, returnKeyType: .done, identifier: serverNameTextFieldIdentifier)

            ])

        self.insertSection(section, at: 0, animated: true)
    }

    private func addCertificateDetails(certificate: OCCertificate) {
        let section =  StaticTableViewSection(headerTitle: "Certificate Details".localized, footerTitle: nil)
        section.add(rows: [
            StaticTableViewRow(rowWithAction: {(staticRow, _) in
				staticRow.section?.viewController?.navigationController?.pushViewController(OCCertificateViewController.init(certificate: certificate), animated: true)
            }, title: "Show Certificate Details".localized, accessoryType: .disclosureIndicator, identifier: certificateDetailsButtonIdentifier)
        ])
        self.addSection(section, animated: true)
    }

    private func addConnectButton() {

        let connectButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: connectButtonSectionIdentifier, rows: [
            StaticTableViewRow(buttonWithAction: { (row, _) in

                var options: [OCAuthenticationMethodKey : Any] = Dictionary()
                var method: String = OCAuthenticationMethodOAuth2Identifier

                if self.authMethodType != nil && self.authMethodType == OCAuthenticationMethodType.passphrase {

                    method = OCAuthenticationMethodBasicAuthIdentifier

                    let username: String? = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphraseUsernameRowIdentifier)?.value as? String
                    let password: String?  = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphrasePasswordIdentifier)?.value as? String

                    options[.usernameKey] = username!
                    options[.passphraseKey] = password!

                }

                options[.presentingViewControllerKey] = self

                let serverName = self.sectionForIdentifier(serverNameSectionIdentifier)?.row(withIdentifier: serverNameTextFieldIdentifier)?.value as? String
                self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
                //TODO:refactor connection buttons and call update
                BookmarkManager.sharedBookmarkManager.saveBookmarks()

                self.connection?.generateAuthenticationData(withMethod: method, options: options, completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in

                    if error == nil {
                        let serverName = self.sectionForIdentifier(serverNameSectionIdentifier)?.row(withIdentifier: serverNameTextFieldIdentifier)?.value as? String
                        self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
                        self.bookmark?.authenticationMethodIdentifier = authenticationMethodIdentifier
                        self.bookmark?.authenticationData = authenticationData

                        switch self.mode {
                        case .add?:
                            print("Add mode")
                            BookmarkManager.sharedBookmarkManager.addBookmark(self.bookmark!)
                        case .edit?:
                            print("Edit mode")
                            BookmarkManager.sharedBookmarkManager.saveBookmarks()
                        default: break
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
            }, title: "Connect".localized,
               style: .proceed,
               identifier: nil)])

        self.addSection(connectButtonSection)

    }

    private func addDeleteAuthDataButton() {
        if let section = self.sectionForIdentifier(connectButtonSectionIdentifier) {
            section.add(rows: [
                StaticTableViewRow(buttonWithAction: { (_, _) in
                    if self.bookmark != nil {

                        BookmarkManager.sharedBookmarkManager.removeAuthDataOfBookmark(self.bookmark!)

                        //TODO: move to update rows
                        self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphraseUsernameRowIdentifier)?.value  = ""
                        self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphrasePasswordIdentifier)?.value  = ""
                        self.tableView.reloadData()
                    }

                }, title: "Delete Authentication Data".localized, style: .destructive, identifier: deleteAuthButtonIdentifier)
                ])
        }
    }

    private func removeContinueButton() {
        if let buttonSection = self.sectionForIdentifier(continueButtonSectionIdentifier) {
            self.removeSection(buttonSection)
        }
    }

    private func addBasicAuthCredentialsFields(username: String?, password: String?) {

        let section = StaticTableViewSection(headerTitle:"Authentication".localized, footerTitle: nil, identifier: passphraseAuthSectionIdentifier, rows:
            [ StaticTableViewRow(textFieldWithAction: nil,
                                 placeholder: "Username".localized,
                                 value: username ?? "",
                                 secureTextEntry: false,
                                 keyboardType: .emailAddress,
                                 autocorrectionType: .no,
                                 autocapitalizationType: UITextAutocapitalizationType.none,
                                 enablesReturnKeyAutomatically: true,
                                 returnKeyType: .continue,
                                 identifier: passphraseUsernameRowIdentifier),

              StaticTableViewRow(textFieldWithAction: nil, placeholder: "Password".localized,
                                 value: password ?? "",
                                 secureTextEntry: true,
                                 keyboardType: .emailAddress,
                                 autocorrectionType: .no,
                                 autocapitalizationType: .none,
                                 enablesReturnKeyAutomatically: true,
                                 returnKeyType: .go,
                                 identifier: passphrasePasswordIdentifier)
            ])
        self.insertSection(section, at: self.sections.count-1, animated: true)
    }

    // MARK: Actions

    lazy private var continueButtonAction: StaticTableViewRowAction  = { (row, _) in

        self.continueAction()

    }

    func continueAction() {

        var username: NSString?
        var password: NSString?
        var afterURL: String = ""

        afterURL = self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.value as? String ?? ""

        var protocolAppended: ObjCBool = false

        if let bookmark: OCBookmark = OCBookmark(for: NSURL(username: &username, password: &password, afterNormalizingURLString: afterURL, protocolWasPrepended: &protocolAppended) as URL),
            let newConnection: OCConnection = OCConnection(bookmark: bookmark) {

            self.bookmark = bookmark
            self.connection = newConnection

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
                        //self.bookmark?.certificate = issuesFromSDK?.certificate
                        self.approveButtonAction(preferedAuthMethods: preferredAuthMethods!, issuesFromSDK: issuesFromSDK!, username: username as String?, password: password as String?)
                    }
                }
            })
        }
    }

    private func approveButtonAction(preferedAuthMethods: [String], issuesFromSDK: OCConnectionIssue?, username: String?, password: String?) {

        self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.value = self.bookmark?.url.absoluteString

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
