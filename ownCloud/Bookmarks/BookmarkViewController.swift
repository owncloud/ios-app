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

//Sections and rows identifiers
let serverURLSectionIdentifier = "server-url-section"
let serverURLTextFieldIdentifier = "server-url-textfield"

let continueButtonSectionIdentifier = "continue-button-section"
let continueButtonRowIdentifier = "continue-button-row"

let serverNameSectionIdentifier = "server-name-section"
let serverNameTextFieldIdentifier = "server-name-textfield"

let passphraseAuthSectionIdentifier = "passphrase-auth-section"
let passphraseUsernameRowIdentifier = "passphrase-username-textfield-row"
let passphrasePasswordIdentifier = "passphrase-password-textfield-row"

let deleteAuthButtonIdentifier = "delete-auth-button"

let certificateDetailsSectionIdentifier = "certificate-details-section"
let certificateDetailsRowIdentifier = "certificate-details-row"

let connectButtonSectionIdentifier = "connect-button-section"
let saveButtonRowIdentifier = "save-button-row-identifier"
let connectButtonRowIdentifier = "connect-button-row-identifier"


enum BookmarkViewControllerMode {
    case add
    case edit
    case update //Auth type has change
}

enum SaveConnectButtonMode {
    case save
    case connect
}

class BookmarkViewController: StaticTableViewController, OCClassSettingsSupport {

    public var bookmark: OCBookmark?
    public var connection: OCConnection?
    
    private var authMethod: String?
    private var mode: BookmarkViewControllerMode?
    private var saveConnectButtonMode: SaveConnectButtonMode?

    convenience init(bookmark: OCBookmark? = nil) {

        self.init(style: UITableViewStyle.grouped)

        self.bookmark = bookmark
        
        if bookmark == nil {
            self.mode = .add
        } else {
            self.mode = .edit
            self.connection = OCConnection(bookmark: self.bookmark)
            self.authMethod = self.bookmark?.authenticationMethodIdentifier
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
            self.addServerUrlSection()
            self.addContinueButton()
            break
        case .edit?:
            self.navigationItem.title = "Edit Server".localized
            
            //Delete button
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete".localized, style: .plain, target: self, action: #selector(deleteBookmark))
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.red
            
            self.addServerNameSection()
            self.addServerUrlSection()
            if self.authMethod == OCAuthenticationMethodBasicAuthIdentifier {
                let username = OCAuthenticationMethodBasicAuth.userName(fromAuthenticationData: self.bookmark?.authenticationData)
                let password = OCAuthenticationMethodBasicAuth.passPhrase(fromAuthenticationData: self.bookmark?.authenticationData)
                self.addBasicAuthCredentialsSection(username: username, password: password)
            }
            if self.bookmark!.certificate != nil {
                self.addCertificateDetailsSection(certificate: self.bookmark!.certificate)
            }
            if self.bookmark?.authenticationData == nil {
                self.addSaveConnectButton(saveConnect: .connect)
            } else {
                self.addSaveConnectButton(saveConnect: .save)
            }
            
            self.tableView.reloadData()
            break
        default: break
        }
    }
    
    private func updateInterfaceAuthMethodChange(issuesFromSDK: OCConnectionIssue?, username: String?, password: String?) {
        
        self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.value = self.bookmark?.url.absoluteString
        
        DispatchQueue.main.async {
            self.addServerNameSection()
            
            if self.authMethod == OCAuthenticationMethodBasicAuthIdentifier {
                self.addBasicAuthCredentialsSection(username: username, password:password)
                self.removeRow(connectButtonSectionIdentifier, rowIdentifier: deleteAuthButtonIdentifier)
            } else {
                if let passphraseAuthSection = self.sectionForIdentifier(passphraseAuthSectionIdentifier) {
                    self.removeSection(passphraseAuthSection)
                }
            }
            
            if let certificateIssue = issuesFromSDK?.issues.filter({ $0.type == .certificate}).first {
                if let certifiateSection = self.sectionForIdentifier(certificateDetailsSectionIdentifier) {
                    self.removeSection(certifiateSection)
                }
                self.addCertificateDetailsSection(certificate: certificateIssue.certificate)
                self.bookmark?.certificate = certificateIssue.certificate
            }
            
            if let continueSection = self.sectionForIdentifier(continueButtonSectionIdentifier) {
                self.removeSection(continueSection)
            }
            if let saveConnectSection = self.sectionForIdentifier(connectButtonSectionIdentifier) {
                self.removeSection(saveConnectSection)
            }
            
            self.addSaveConnectButton(saveConnect: .connect)
            self.tableView.reloadData()
        }
    }
    
    // MARK: Interface sections

    private func addServerUrlSection() {
        
        var serverURLName = self.classSetting(forOCClassSettingsKey: BookmarkDefaultURLKey) as? String ?? ""

        if let url = self.bookmark?.url {
            serverURLName = url.absoluteString
        }

        let serverURLSection: StaticTableViewSection = StaticTableViewSection(headerTitle:"Server URL".localized, footerTitle: nil, identifier: serverURLSectionIdentifier)

        serverURLSection.add(rows: [self.getUrlRow(serverURLName: serverURLName)])
        addSection(serverURLSection, animated: false)
    }

    private func addContinueButton() {

        let continueButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: continueButtonSectionIdentifier, rows: [
            self.getContinueButtonRow()
            ])

        self.addSection(continueButtonSection, animated: false)
    }

    private func addServerNameSection() {
        
        if self.sectionForIdentifier(serverNameSectionIdentifier) == nil {
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
    }

    private func addCertificateDetailsSection(certificate: OCCertificate) {
        let section =  StaticTableViewSection(headerTitle: "Certificate Details".localized, footerTitle: nil, identifier: certificateDetailsSectionIdentifier)
        section.add(rows: [
            self.getCertificateDetailsRow(certificate: certificate)
        ])
        self.addSection(section, animated: true)
    }
    
    private func addSaveConnectButton(saveConnect: SaveConnectButtonMode) {
     
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
        
        if self.authMethod == OCAuthenticationMethodOAuth2Identifier {
            section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: connectButtonSectionIdentifier, rows: [saveConnectRow, self.getDeleteAuthDataButtonRow()])
        } else {
            section = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: connectButtonSectionIdentifier, rows: [saveConnectRow])
        }
        
        self.addSection(section!, animated: true)
    }
    
    private func addBasicAuthCredentialsSection(username: String?, password: String?) {
    
        let section = StaticTableViewSection(headerTitle:"Authentication".localized, footerTitle: nil, identifier: passphraseAuthSectionIdentifier, rows:
            [self.getUsernameRow(username: username),
             self.getPasswordRow(password: password)
            ])
        
        self.addSection(section, animated: true)
    }

    // MARK: Rows
    
    func getUrlRow(serverURLName: String) -> StaticTableViewRow {
        
        let isEnabledURLTextField = self.classSetting(forOCClassSettingsKey: BookmarkURLEditableKey) as? Bool ?? true
        
        let row: StaticTableViewRow = StaticTableViewRow(textFieldWithAction: { (row, _) in
            if self.mode == .edit {
                self.urlTextFieldDidChange(newURL: row.value as! String)
            }
        },
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
        
        let isEnableUsernameTextField: Bool = (self.mode == .add || self.mode == .update) ? true : false
        
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
            if self.mode == .edit && self.bookmark?.authenticationMethodIdentifier == OCAuthenticationMethodBasicAuthIdentifier {
                self.passwordTextFieldDidChange(newPassword: row.value as! String)
            }
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
    
    func getCertificateDetailsRow(certificate: OCCertificate) -> StaticTableViewRow {
        let row = StaticTableViewRow(rowWithAction: {(staticRow, _) in
            staticRow.section?.viewController?.navigationController?.pushViewController(OCCertificateViewController.init(certificate: certificate), animated: true)
        }, title: "Show Certificate Details".localized,
           accessoryType: .disclosureIndicator,
           identifier: certificateDetailsRowIdentifier)
        
        return row
    }
    
    func getSaveButtonRow() -> StaticTableViewRow {
        
        self.saveConnectButtonMode = .save
        
        let row = StaticTableViewRow(buttonWithAction: { (row, _) in
            
            self.saveButtonAction()
            
        }, title: "Save".localized,
           style: .proceed,
           identifier: saveButtonRowIdentifier)
        
        return row
    }
    
    func getContinueButtonRow() -> StaticTableViewRow {
        let row = StaticTableViewRow(buttonWithAction: { (row, _) in
            
            self.continueButtonAction()
            
        }, title: "Continue".localized,
                                     style: .proceed,
                                     identifier: continueButtonRowIdentifier)
        
        return row
    }
    
    func getConnectButtonRow() -> StaticTableViewRow {
        
        self.saveConnectButtonMode = .connect
        
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

   private func continueButtonAction() {
        self.checkServerBeforeConnect(usernameConst: nil, passwordConst: nil)
    }
    
    private func saveButtonAction() {
        
        let serverName = self.sectionForIdentifier(serverNameSectionIdentifier)?.row(withIdentifier: serverNameTextFieldIdentifier)?.value as? String
        self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
        BookmarkManager.sharedBookmarkManager.saveBookmarks()
        
        self.connectButtonAction()
    }
    
    private func connectButtonAction() {
        
        let username: NSString? = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphraseUsernameRowIdentifier)?.value as? NSString
        let password: NSString?  = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphrasePasswordIdentifier)?.value as? NSString

        self.checkServerBeforeConnect(usernameConst: username, passwordConst: password)
    }
    
    func deleteAuthDataButtonAction() {
        if let bookmark = self.bookmark {
            self.bookmark = BookmarkManager.sharedBookmarkManager.removeAuthDataOfBookmark(bookmark)
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: saveButtonRowIdentifier, newRow: self.getConnectButtonRow())
            self.tableView.reloadData()
        }
    }
    
    func checkServerBeforeConnect(usernameConst: NSString?, passwordConst: NSString?) {
        var username: NSString? = usernameConst
        var password: NSString? = passwordConst
        
        var afterURL: String = ""
        
        afterURL = self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.value as? String ?? ""
        
        var protocolAppended: ObjCBool = false
        
        if self.connection != nil {
            self.connection?.prepareForSetup(options: nil, completionHandler: { (issuesFromSDK, _, _, preferredAuthMethods) in
                self.managePrepareForSetupResultConnection(issuesFromSDK: issuesFromSDK!, preferredAuthMethods: preferredAuthMethods! as [OCAuthenticationMethodIdentifier], username: username, password: password)
            })
        } else {
            if let bookmark: OCBookmark = OCBookmark(for: NSURL(username: &username, password: &password, afterNormalizingURLString: afterURL, protocolWasPrepended: &protocolAppended) as URL),
                let newConnection: OCConnection = OCConnection(bookmark: bookmark) {
                
                self.bookmark = bookmark
                self.connection = newConnection
                
                newConnection.prepareForSetup(options: nil, completionHandler: { (issuesFromSDK, _, _, preferredAuthMethods) in
                    self.managePrepareForSetupResultConnection(issuesFromSDK: issuesFromSDK!, preferredAuthMethods: preferredAuthMethods! as [OCAuthenticationMethodIdentifier], username: username, password: password)
                })
            }
        }
    }
    
    func managePrepareForSetupResultConnection(issuesFromSDK: OCConnectionIssue, preferredAuthMethods: [OCAuthenticationMethodIdentifier], username: NSString?, password: NSString?) {
        
        //Auth method
        let preferedAuthMethod = preferredAuthMethods.first as String?
        var authMethod: String?
        
        if preferredAuthMethods.count > 0 {
            if OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: preferedAuthMethod).type() == .passphrase {
                authMethod = OCAuthenticationMethodBasicAuthIdentifier
            } else {
                authMethod = OCAuthenticationMethodOAuth2Identifier
            }
        } else {
            
        }
        
        if let issues = issuesFromSDK.issuesWithLevelGreaterThanOrEqual(to: OCConnectionIssueLevel.warning),
            issues.count > 0 {
            
            switch self.saveConnectButtonMode {
            case .save?:
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
                break
            case .connect?:
                DispatchQueue.main.async {
                    let issuesVC = ConnectionIssueViewController(issue: issuesFromSDK, completion: {
                        (result) in
                        
                        if result == ConnectionResponse.approve {
                            
                            for issue in issues {
                                issue.approve()
                            }
                            
                            DispatchQueue.main.async {
                                self.continueAfterCheckConnection(authMethod: authMethod!, issuesFromSDK: issuesFromSDK, username: username as String?, password: password as String?)
                            }
                        }
                        
                    })
                    
                    issuesVC.modalPresentationStyle = .overCurrentContext
                    self.present(issuesVC, animated: true, completion: nil)
                }
            default: break
            }
        } else {
            self.continueAfterCheckConnection(authMethod: authMethod!, issuesFromSDK: issuesFromSDK, username: username as String?, password: password as String?)
        }
    }
    
    func continueAfterCheckConnection(authMethod:String, issuesFromSDK: OCConnectionIssue?, username: String?, password: String?) {
        
        if self.authMethod == nil || self.authMethod != authMethod {
            
            //Auth method change so enter in .update mode
            if (self.authMethod != nil) {
                self.mode = .update
            }
            
            self.authMethod = authMethod
            
            DispatchQueue.main.async {
                self.updateInterfaceAuthMethodChange(issuesFromSDK: issuesFromSDK, username: username as String?, password: password as String?)
            }
        } else {
            switch self.saveConnectButtonMode {
            case .save?:
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
                break
            case .connect?:
                self.connect()
            default: break
            }
        }
    }
    
    func connect() {
        var options: [OCAuthenticationMethodKey : Any] = Dictionary()
        
        if self.authMethod != nil && self.authMethod == OCAuthenticationMethodBasicAuthIdentifier {
            
            let username: String? = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphraseUsernameRowIdentifier)?.value as? String
            let password: String?  = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphrasePasswordIdentifier)?.value as? String
            
            options[.usernameKey] = username!
            options[.passphraseKey] = password!
            
        }
        
        options[.presentingViewControllerKey] = self
        
        let serverName = self.sectionForIdentifier(serverNameSectionIdentifier)?.row(withIdentifier: serverNameTextFieldIdentifier)?.value as? String
        self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
        
        self.connection?.generateAuthenticationData(withMethod: self.authMethod!, options: options, completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in
            
            if error == nil {
                let serverName = self.sectionForIdentifier(serverNameSectionIdentifier)?.row(withIdentifier: serverNameTextFieldIdentifier)?.value as? String
                self.bookmark?.name = (serverName != nil && serverName != "") ? serverName: self.bookmark!.url.absoluteString
                self.bookmark?.authenticationMethodIdentifier = authenticationMethodIdentifier
                self.bookmark?.authenticationData = authenticationData
                
                switch self.mode {
                case .add?:
                    BookmarkManager.sharedBookmarkManager.addBookmark(self.bookmark!)
                case .edit?:
                    BookmarkManager.sharedBookmarkManager.saveBookmarks()
                case .update?:
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
    
    //MARK: TextFieldDidChange
    func passwordTextFieldDidChange(newPassword: String) {
        
        let originalPassword = OCAuthenticationMethodBasicAuth.passPhrase(fromAuthenticationData: self.bookmark?.authenticationData)
        
        let actualURL:String = self.sectionForIdentifier(serverURLSectionIdentifier)?.row(withIdentifier: serverURLTextFieldIdentifier)?.value as! String
        
        if newPassword == originalPassword && actualURL == self.bookmark?.url.absoluteString {
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: connectButtonRowIdentifier, newRow: self.getSaveButtonRow())
        } else {
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: saveButtonRowIdentifier, newRow: self.getConnectButtonRow())
        }
    }
    
    func urlTextFieldDidChange(newURL: String) {
        
        var actualPassword:String = ""
        var originalPassword:String = ""
        
        if self.authMethod == OCAuthenticationMethodBasicAuthIdentifier {
            actualPassword = self.sectionForIdentifier(passphraseAuthSectionIdentifier)?.row(withIdentifier: passphrasePasswordIdentifier)?.value as! String
            originalPassword = OCAuthenticationMethodBasicAuth.passPhrase(fromAuthenticationData: self.bookmark?.authenticationData)
        }
        
        if newURL == self.bookmark?.url.absoluteString && actualPassword == originalPassword && self.bookmark?.authenticationData != nil {
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: connectButtonRowIdentifier, newRow: self.getSaveButtonRow())
        } else {
            self.replaceRow(connectButtonSectionIdentifier, rowIdentifier: saveButtonRowIdentifier, newRow: self.getConnectButtonRow())
        }
    }
}
