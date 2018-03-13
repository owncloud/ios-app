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
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

enum BookmarkViewControllerMode {
	case add
	case edit
}

class BookmarkViewController: StaticTableViewController {

	public var mode : BookmarkViewControllerMode = .add
    private var bookmarkToAdd : OCBookmark?
    private var connection: OCConnection?
    private var authMethodType: OCAuthenticationMethodType?

	override func viewDidLoad() {
		super.viewDidLoad()

        DispatchQueue.main.async {
            switch self.mode {
            case .add:
                self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("Add Server", comment: "")
                self.addServerUrl()
                self.addContinueButton()

            case .edit:
                // TODO: Make this go directly to the edit view with all the things.
                self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("Edit Server", comment: "")
                self.addServerName()
                self.addServerUrl()
                self.addConnectButton()
                self.addDeleteAuthDataButton()
                self.tableView.reloadData()
            }
        }

	}

    private func addServerUrl() {
        let serverURLSection = StaticTableViewSection(headerTitle:NSLocalizedString("Server Url", comment: ""), footerTitle: nil, identifier: "server-url-section", rows: [
            StaticTableViewRow(textFieldWithAction: { (_, _) in},
                               placeholder: NSLocalizedString("https://example.com", comment: ""),
                               value: "",
                               keyboardType: .default,
                               autocorrectionType: .no,
                               autocapitalizationType: .none,
                               enablesReturnKeyAutomatically: false,
                               returnKeyType: .continue,
                               identifier: "server-url-textfield")
            ])
        self.addSection(serverURLSection, animated: true)
    }

    private func addContinueButton() {
        let continueButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "continue-button-section", rows: [
            StaticTableViewRow(buttonWithAction: { (row, _) in

                if let serverURL: String = row.section?.viewController?.sectionForIdentifier("server-url-section")?.row(withIdentifier: "server-url-textfield")?.value as? String,
                    let url: URL = URL(string: serverURL),
                    let bookmark: OCBookmark = OCBookmark(for: url),
                    let connection: OCConnection = OCConnection(bookmark: bookmark) {

                    row.selectable = false

                    self.bookmarkToAdd = bookmark
                    self.connection = connection
                    connection.prepareForSetup(options: nil, completionHandler: { (issue, _, _, preferedAuthMethods) in

                        let issues: [OCConnectionIssue]? = issue?.issuesWithLevelGreaterThanOrEqual(to: OCConnectionIssueLevel.error)
                        let warningAndErrorIssues : [OCConnectionIssue]? = issue?.issuesWithLevelGreaterThanOrEqual(to: OCConnectionIssueLevel.warning)

                        row.selectable = true

                        if issues != nil && issues!.count > 0 {
                            // TODO: present issues to the user.
                            DispatchQueue.main.async {
                                self.present(UIAlertController(title: "ErrorIssues", message: "ErrorIssues", preferredStyle: .alert), animated: true, completion: nil)
                            }

                        } else {
                            if warningAndErrorIssues != nil && warningAndErrorIssues!.count > 0 {
                                // TODO: ask the user for confirmation
                                DispatchQueue.main.async {
                                    self.present(UIAlertController(title: "warningAndErrorIssues", message: "warningAndErrorIssues", preferredStyle: .alert), animated: true, completion: nil)
                                }

                            } else {
                                let authMethodType = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: preferedAuthMethods?.first).type()
                                self.authMethodType = authMethodType

                                DispatchQueue.main.async {
                                    self.addServerName()
                                    if issue?.issues.filter({ $0.type == .certificate}) != nil {
                                        self.addCertificateDetails()
                                    }

                                    if authMethodType == .passphrase {
                                        self.showBasicAuthCredentials()
                                    }
                                    self.removeContinueButton()
                                    self.addConnectButton()
                                    self.tableView.reloadData()
                                }
                            }
                        }

                    })
                }
            }, title: NSLocalizedString("Continue", comment: ""), style: .proceed, identifier: "continue-button-row")
            ])

        self.addSection(continueButtonSection, animated: true)
    }

    private func addServerName() {

        var serverName = ""
        switch self.mode {
        case .add:
            break
        case .edit:
            if let name = self.bookmarkToAdd?.name {
                serverName = name
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

        self.addSection(section, at: 0)
    }

    private func addCertificateDetails() {
        let section =  self.sectionForIdentifier("server-url-section")
        section?.add(rows: [
            StaticTableViewRow(rowWithAction: {(_, _) in

            }, title: NSLocalizedString("Show Certificate Details", comment: ""), accessoryType: .disclosureIndicator, identifier: "certificate-details-button")
            ])
    }

    private func addConnectButton() {
        let connectButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "connect-button-section", rows: [
            StaticTableViewRow(buttonWithAction: {(_, _) in

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

                self.connection?.generateAuthenticationData(withMethod: method, options: options, completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in

                    if error == nil {
                        let serverName = self.sectionForIdentifier("server-name-section")?.row(withIdentifier: "server-name-textfield")?.value as? String
                        self.bookmarkToAdd?.name = (serverName != nil && serverName != "") ? serverName: self.bookmarkToAdd!.url.absoluteString
                        self.bookmarkToAdd?.authenticationMethodIdentifier = authenticationMethodIdentifier
                        self.bookmarkToAdd?.authenticationData = authenticationData
                        BookmarkManager.sharedBookmarkManager.addBookmark(self.bookmarkToAdd!)

                        DispatchQueue.main.async {
                            self.navigationController?.pushViewController(ServerListTableViewController.init(style: .grouped), animated: true)
                        }
                    }
                })
            }, title: NSLocalizedString("Connect", comment: ""))
            ])
        self.addSection(connectButtonSection)

    }

    private func addDeleteAuthDataButton() {
        if let section = self.sectionForIdentifier("connect-button-section") {
            section.add(rows: [
                StaticTableViewRow(buttonWithAction: { (_, _) in
                    if let bookmark = self.bookmarkToAdd {
                        bookmark.authenticationData = nil
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

    private func showBasicAuthCredentials() {
        let section = StaticTableViewSection(headerTitle:NSLocalizedString("Authentication", comment: ""), footerTitle: nil, identifier: "passphrase-auth-section", rows:
            [ StaticTableViewRow(textFieldWithAction: {(_, _) in

            }, placeholder: NSLocalizedString("Username", comment: ""),
               value: "",
               secureTextEntry: false,
               keyboardType: .emailAddress,
               autocorrectionType: .no,
               autocapitalizationType: UITextAutocapitalizationType.none,
               enablesReturnKeyAutomatically: true,
               returnKeyType: .continue,
               identifier: "passphrase-username-textfield-row"),

            StaticTableViewRow(textFieldWithAction: {(_, _) in

            }, placeholder: NSLocalizedString("Password", comment: ""),
               value: "",
               secureTextEntry: true,
               keyboardType: .emailAddress,
               autocorrectionType: .no,
               autocapitalizationType: .none,
               enablesReturnKeyAutomatically: true,
               returnKeyType: .go,
               identifier: "passphrase-password-textfield-row")
            ])
        self.addSection(section, at: self.sections.count-1)
    }
}
