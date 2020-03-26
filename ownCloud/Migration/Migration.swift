//
//  Migration.swift
//  ownCloud
//
//  Created by Michael Neuwert on 03.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import Foundation
import ownCloudSDK

class Migration {
	
	struct Entitlements : Codable {
		
		var appGroups : [String]?
		var keychainAccessGroups : [String]?
		
		enum CodingKeys: String, CodingKey {
			case appGroups = "com.apple.security.application-groups"
			case keychainAccessGroups = "keychain-access-groups"
		}
	}
	
	private static let legacyDbFilename = "DB.sqlite"
	private static let legacyCacheFolder = "cache_folder"

	static let shared = Migration()
	
	private lazy var appGroupId : String? = {
		// Try to read entitlements
		if let entitlements = readAppEntitlements() {
			return entitlements.appGroups?.first
		}
		
		// Try to construct group id from bundle identifier
		if let bundleId = Bundle.main.bundleIdentifier {
			return "group." + bundleId
		}
		
		return nil
	}()
	
	private lazy var legacyDataDirectoryURL: URL? = {
		if let groupId = self.appGroupId {
			let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId)
			return containerURL?.appendingPathComponent(Migration.legacyCacheFolder)
		}
		return nil
	}()
	
	// MARK: - Public API
	
	var legacyDataFound : Bool {
		get {
			var isDirectory : ObjCBool = false
			if let directoryPath = self.legacyDataDirectoryURL?.path {
				let pathExists = FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory)
				return (pathExists && isDirectory.boolValue == true)
			}
			return false
		}
	}
	
	func migrateAccountsAndSettings() {
		
		guard let legacyDbURL = self.legacyDataDirectoryURL?.appendingPathComponent(Migration.legacyDbFilename) else { return }
		
		if FileManager.default.fileExists(atPath: legacyDbURL.path) {
			let db = OCSQLiteDB(url: legacyDbURL)
			db.open(with: .readOnly) { (_, err) in
				if err == nil {
					let queryResultHandler : OCSQLiteDBResultHandler = { (db, error, transaction, resultSet) in
						if let resultSet = resultSet {
							var error : NSError? = nil
							
							resultSet.iterate( { (result, line, rowDict, stop) in
								if let userId = rowDict["id"] as? Int,
									let serverURL = rowDict["url"] as? String,
									let credentials = self.getCredentialsDataItem(for: userId) {
									
									let bookmark = OCBookmark()
									bookmark.url = URL(string: serverURL)
									
									let connection = OCConnection(bookmark: bookmark)
									var options : [OCAuthenticationMethodKey : Any] = [:]
									
									switch credentials.authenticationMethod {
									case .basicHttpAuth:

										connection.prepareForSetup(options: nil) { (issue, _, _, preferredAuthenticationMethods) in
											// TODO: Check for issues
											
											if let methods = preferredAuthenticationMethods, methods.contains(OCAuthenticationMethodIdentifier.oAuth2) {
												// TODO: If server supports OAut 2.0 -> Move to OAuth 2.0
											}
											
											options[.usernameKey] = credentials.userName
											options[.passphraseKey] = credentials.accessToken
											
											connection.generateAuthenticationData(withMethod: OCAuthenticationMethodIdentifier.basicAuth, options: options) { (error, authMethodIdentifier, authMethodData) in
												if error == nil {
													bookmark.authenticationMethodIdentifier = authMethodIdentifier
													bookmark.authenticationData = authMethodData
													
													OCBookmarkManager.shared.addBookmark(bookmark)
													OCBookmarkManager.shared.saveBookmarks()
												}
											}
										}
										
									case .bearerToken:
										break
									case .samlWebSSO:
										break
									default:
										 break
									}
								}

							}, error: &error)
						}
					}
					
					if let usersQuery = OCSQLiteQuery(selectingColumns: nil, fromTable: "users", where: nil, orderBy: nil, limit: nil, resultHandler: queryResultHandler) {
						db.execute(usersQuery)
					}
					
				}
			}
		}
	}
	
	func wipeLegacyData() {
		
	}
	
	// MARK: - Private helpers
	
	private func authenticationMethodTypeForIdentifier(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> OCAuthenticationMethodType? {
		if let authenticationMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethodIdentifier) {
			return authenticationMethodClass.type
		}

		return nil
	}

	private func isAuthenticationMethodPassphraseBased(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> Bool {
		return authenticationMethodTypeForIdentifier(authenticationMethodIdentifier) == OCAuthenticationMethodType.passphrase
	}

	private func isAuthenticationMethodTokenBased(_ authenticationMethodIdentifier: OCAuthenticationMethodIdentifier) -> Bool {
		return authenticationMethodTypeForIdentifier(authenticationMethodIdentifier) == OCAuthenticationMethodType.token
	}
	
	private func getCredentialsDataItem(for userId:Int) -> OCCredentialsDto? {
		
		guard let groupId = self.appGroupId else { return nil }
		guard let bundleSeed = self.bundleSeedID() else { return nil }
		
		let fullGroupId = "\(bundleSeed).\(groupId)"
		
		let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
									kSecAttrAccessGroup as String: fullGroupId,
									kSecAttrAccount as String: "\(userId)",
									kSecReturnData as String : true,
									kSecReturnAttributes as String : true]
		
		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		if status == errSecSuccess {
			guard let existingItem = item as? [String : Any],
				let credentialsData = existingItem[kSecValueData as String] as? Data
			else {
				return nil
			}
			
			let credentials = NSKeyedUnarchiver.unarchiveObject(with: credentialsData) as? OCCredentialsDto
			
			return credentials
		}
		
		return nil
	}
	
	private func removeCredentials(for userId:Int) {
		guard let groupId = self.appGroupId else { return }
		guard let bundleSeed = self.bundleSeedID() else { return }
		
		let fullGroupId = "\(bundleSeed).\(groupId)"
		
		let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
									kSecAttrAccessGroup as String: fullGroupId,
									kSecAttrAccount as String: "\(userId)"]
		let status = SecItemCopyMatching(query as CFDictionary, nil)
		if status != errSecSuccess {
			 SecItemDelete(query as CFDictionary)
		}
	}
	
	private func readAppEntitlements() -> Entitlements? {
		guard let productName = Bundle.main.infoDictionary?[String(kCFBundleNameKey)] as? String else { return nil }
		guard let entitlementsPath = Bundle.main.path(forResource: productName, ofType: "entitlements") else { return nil }
		guard let plistData = FileManager.default.contents(atPath: entitlementsPath) else { return nil}
		
		var entitlements : Entitlements?
		let decoder = PropertyListDecoder()
		entitlements = try? decoder.decode(Entitlements.self, from: plistData)
		
		return entitlements
	}
	
	private func bundleSeedID() -> String? {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "bundleSeedID" as AnyObject,
            kSecAttrService as String: "" as AnyObject,
            kSecReturnAttributes as String: kCFBooleanTrue
        ]

        var result : AnyObject?
        var status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status == errSecItemNotFound {
            status = withUnsafeMutablePointer(to: &result) {
                SecItemAdd(query as CFDictionary, UnsafeMutablePointer($0))
            }
        }

        if status == noErr {
            if let resultDict = result as? [String: Any], let accessGroup = resultDict[kSecAttrAccessGroup as String] as? String {
                let components = accessGroup.components(separatedBy: ".")
                return components.first
            }
		}
		
		return nil
    }
}
