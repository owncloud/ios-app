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

let saveButtonRowIdentifier = "save-button-row-identifier"
let connectButtonRowIdentifier = "connect-button-row-identifier"


enum BookmarkViewControllerMode {
    case add
    case edit
}

enum SaveConnectButtonmode {
    case save
    case connect
}

class BookmarkViewController: StaticTableViewController, OCClassSettingsSupport {

    public var bookmark: OCBookmark?
    public var connection: OCConnection?
    private var authMethod: String?
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

    // MARK: Interface configuration
    
    private func loadInterface() {

        switch self.mode {
        case .add?:
            self.navigationItem.title = "Add Server".localized
            self.addServerUrl()
            self.addContinueButton(action: self.continueButtonAction)
        case .edit?:
            self.navigationItem.title = "Edit Server".localized
            
            //Right button
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete".localized, style: .plain, target: self, action: #selector(deleteBookmark))
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.red
            
            self.addServerName()
            self.addServerUrl()
            if self.bookmark?.authenticationMethodIdentifier == OCAuthenticationMethodBasicAuthIdentifier {
                let username = OCAuthenticationMethodBasicAuth.userName(fromAuthenticationData: self.bookmark?.authenticationData)
                let password = OCAuthenticationMethodBasicAuth.passPhrase(fromAuthenticationData: self.bookmark?.authenticationData)
                self.addBasicAuthCredentialsFields(username: username, password: password)
            }
            //TODO: not working, the certificate is nil
            //self.addCertificateDetails(certificate: self.bookmark!.certificate)
            if self.bookmark?.authenticationData == nil {
                self.addSaveConnectButton(saveConnect: .connect)
            } else {
                self.addSaveConnectButton(saveConnect: .save)
            }
            
            
            self.tableView.reloadData()

            self.connection = OCConnection(bookmark: self.bookmark)

        default: break
        }

    }

    private func updateConnect() {
        
    }
    
    // MARK: Interface sections

    private func addServerUrl() {
        
        var serverURLName = self.classSetting(forOCClassSettingsKey: BookmarkDefaultURLKey) as? String ?? ""

        if let url = self.bookmark?.url {
            serverURLName = url.absoluteString
        }

        let serverURLSection: StaticTableViewSection = StaticTableViewSection(headerTitle:"Server URL".localized, footerTitle: nil, identifier: serverURLSectionIdentifier)

        serverURLSection.add(rows: [self.getUrlRow(serverURLName: serverURLName)])
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

                self.connectButtonAction()
                
            }, title: "Connect".localized,
               style: .proceed,
               identifier: nil)])
        
        self.addSection(connectButtonSection, animated: true)

    }
    
    private func addSaveConnectButton(saveConnect: SaveConnectButtonmode) {
     
        var saveConnectRow:StaticTableViewRow
        
        switch saveConnect {
        case .save:
            saveConnectRow = self.getSaveButtonRow()
        case .connect:
            saveConnectRow = self.getConnectButtonRow()
        }
        
        var section = self.sectionForIdentifier(connectButtonSectionIdentifier)
        
        if section == nil {
        } else {
            self.removeSection(section!, animated: true)
        }
        
        section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: connectButtonSectionIdentifier, rows: [saveConnectRow, self.getDeleteAuthDataButtonRow()])
        
        self.addSection(section!, animated: true)
    }

    private func removeContinueButton() {
        if let buttonSection = self.sectionForIdentifier(continueButtonSectionIdentifier) {
            self.removeSection(buttonSection)
        }
    }

    private func addBasicAuthCredentialsFields(username: String?, password: String?) {
    
        let section = StaticTableViewSection(headerTitle:"Authentication".localized, footerTitle: nil, identifier: passphraseAuthSectionIdentifier, rows:
            [self.getUsernameRow(username: username),
             self.getPasswordRow(password: password)
            ])
        
        self.insertSection(section, at: self.sections.count-1, animated: true)
    }

    // MARK: Rows
    
    func getUrlRow(serverURLName: String) -> StaticTableViewRow {
        
        let isEnabledURLTextField = self.classSetting(forOCClassSettingsKey: BookmarkURLEditableKey) as? Bool ?? true
        
        let row: StaticTableViewRow = StaticTableViewRow(textFieldWithAction: nil,
                                                                  placeholder: "https://example.com".localized,
                                                                  value: serverURLName,
                                                                  keyboardType: .default,
                                                                  autocorrectionType: .no,
                                                                  autocapitalizationType: .none,
                                                                  enablesReturnKeyAutomatically: false,
                                                                  returnKeyType: .continue,
                                                                  identifier: serverURLTextFieldIdentifier,
                                                                  isEnabled: isEnabledURLTextField)
        
        return row
    }
    
    func getUsernameRow(username: String?) -> StaticTableViewRow {
        
        let isEnableUsernameTextField: Bool = (self.mode == .add) ? true : false
        
        let row = StaticTableViewRow(textFieldWithAction: nil,
                                     placeholder: "Username".localized,
                                     value: username ?? "",
                                     secureTextEntry: false,
                                     keyboardType: .emailAddress,
                                     autocorrectionType: .no,
                                     autocapitalizationType: UITextAutocapitalizationType.none,
                                     enablesReturnKeyAutomatically: true,
                                     returnKeyType: .continue,
                                     identifier: passphraseUsernameRowIdentifier,
                                     isEnabled:isEnableUsernameTextField)
        
        return row
    }
    
    func getPasswordRow(password: String?) -> StaticTableViewRow {
        let row = StaticTableViewRow(textFieldWithAction: { (row, _) in
            self.passwordTextFieldDidChange(newPassword: row.value as! String)
        },
                                     placeholder: "Password".localized,
                                     value: password ?? "",
                                     secureTextEntry: true,
                                     keyboardType: .emailAddress,
                                     autocorrectionType: .no,
                                     autocapitalizationType: .none,
                                     enablesReturnKeyAutomatically: true,
                                     returnKeyType: .go,
                                     identifier: passphrasePasswordIdentifier)
        
        return row
    }
    
    func getSaveButtonRow() -> StaticTableViewRow {
        let row = StaticTableViewRow(buttonWithAction: { (row, _) in
            
            self.saveButtonAction()
            
        }, title: "Save".localized,
           style: .proceed,
           identifier: saveButtonRowIdentifier)
        
        return row
    }
    
    func getConnectButtonRow() -> StaticTableViewRow {
        let row = StaticTableViewRow(buttonWithAction: { (row, _) in
            
            self.connectButtonAction()
            
        }, title: "Connect".localized,
           style: .proceed,
           identifier: connectButtonRowIdentifier)
        
        return row
    }
    
    func getDeleteAuthDataButtonRow() -> StaticTableViewRow {
        let row = StaticTableViewRow(buttonWithAction: { (_, _) in
            self.deleteAuthDataButtonAction()
        }, title: "Delete Authentication Data".localized, style: .destructive, identifier: deleteAuthButtonIdentifier)
        
        return row
    }
    
    // MARK: Actions
    
    @IBAction func deleteBookmark() {
        let alertController = UIAlertController.init(title: NSString.init(format: NSLocalizedString("Really delete '%@'?", comment: "") as NSString, self.bookmark?.name as! NSString) as String,
                                                     message: NSLocalizedString("This will also delete all locally stored file copies.", comment: ""),
                                                     preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction.init(title: "Cancel".localized, style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction.init(title: "Delete".localized, style: .destructive, handler: { (_) in
            
            BookmarkManager.sharedBookmarkManager.removeBookmark(self.bookmark!)
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }

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
                        let issuesVC = ConnectionIssueViewController(issue: issuesFromSDK!, completion: {
                            (result) in

                            if result == ConnectionResponse.approve {
                                DispatchQueue.main.async {
                                    //self.bookmark?.certificate = issuesFromSDK?.certificate
                                    self.approveButtonAction(preferedAuthMethods: preferredAuthMethods!, issuesFromSDK: issuesFromSDK!, username: username as String?, password: password as String?)
                                }
                            }

                        })

                        issuesVC.modalPresentationStyle = .overCurrentContext
                        self.present(issuesVC, animated: true, completion: nil)
                    }
                } else {

                    self.authMethod = self.bookmark?.authenticationMethodIdentifier

                    DispatchQueue.main.async {
                        //self.bookmark?.certificate = issuesFromSDK?.certificate
                        self.approveButtonAction(preferedAuthMethods: preferredAuthMethods!, issuesFromSDK: issuesFromSDK!, username: username as String?, password: password as String?)
                    }
                }
            })
        }
    }
    
    private func saveButtonAction() {
        let serverName = self.sectionForIdentifier(serverNameSectionIdentifier)?.row(withIdentifier: serverNameTextFieldIdentifier)?.value as? String
        self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
        BookmarkManager.sharedBookmarkManager.saveBookmarks()
        
        self.navigationController?.popViewController(animated: true)
    }
    
    private func connectButtonAction() {
        var options: [OCAuthenticationMethodKey : Any] = Dictionary()
        
        if self.mode == .edit {
            self.authMethod = self.bookmark?.authenticationMethodIdentifier
        }
        
        if self.authMethod != nil && self.authMethod == OCAuthenticationMethodBasicAuthIdentifier {
            
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
        
        self.connection?.generateAuthenticationData(withMethod: self.authMethod!, options: options, completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in
            
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
                    let issuesVC = ConnectionIssueViewController(issue: OCConnectionIssue(forError: error, level: OCConnectionIssueLevel.error, issueHandler: nil), completion: {
                        (result) in
                        // TODO
                    })
                    issuesVC.modalPresentationStyle = .overCurrentContext
                    self.present(issuesVC, animated: true, completion: nil)
                }
            }
        })
    }
    
    private func approveButtonAction(preferedAuthMethods: [String], issuesFromSDK: OCConnectionIssue?, username: String?, password: String?) {

        self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.value = self.bookmark?.url.absoluteString

        if let preferedAuthMethod = preferedAuthMethods.first as String? {

            DispatchQueue.main.async {
                self.addServerName()
                if let certificateIssue = issuesFromSDK?.issues.filter({ $0.type == .certificate}).first {
                    self.addCertificateDetails(certificate: certificateIssue.certificate)
                }

                if OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: preferedAuthMethod).type() == .passphrase {
                    self.authMethod = OCAuthenticationMethodBasicAuthIdentifier
                    self.addBasicAuthCredentialsFields(username: username, password:password)
                } else {
                    self.authMethod = OCAuthenticationMethodOAuth2Identifier
                }

                self.removeContinueButton()
                self.addConnectButton()
                self.tableView.reloadData()
            }
        }
    }
    
    func deleteAuthDataButtonAction() {
        if self.bookmark != nil {
            self.bookmark = BookmarkManager.sharedBookmarkManager.removeAuthDataOfBookmark(self.bookmark!)
            self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphrasePasswordIdentifier)?.value  = ""
            self.tableView.reloadData()
        }
    }
    
    //MARK: Utils
    func passwordTextFieldDidChange(newPassword: String) {
        
        let originalPassword = OCAuthenticationMethodBasicAuth.passPhrase(fromAuthenticationData: self.bookmark?.authenticationData)
        
        if newPassword == originalPassword {
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: connectButtonRowIdentifier, newRow: self.getSaveButtonRow())
        } else {
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: saveButtonRowIdentifier, newRow: self.getConnectButtonRow())
        }
    }
}
