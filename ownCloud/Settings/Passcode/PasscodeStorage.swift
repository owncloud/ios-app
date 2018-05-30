//
//  PasscodeStorage.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 29/05/2018.
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

class PasscodeStorage: NSObject {

    static let passcodeKeychainAccount = "passcode-keychain-account"
    static let passcodeKeychainPath = "passcode-keychain-path"

    static var isPasscodeStoredOnKeychain: Bool {
        return (OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil)
    }

    static var passcodeFromKeychain: String? {
        if let passcodeData = OCAppIdentity.shared().keychain.readDataFromKeychainItem(
            forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) {
            return NSKeyedUnarchiver.unarchiveObject(with: passcodeData) as? String
        } else {
            return nil
        }
    }

    static func writePasscodeInKeychain(passcode: String) {
        OCAppIdentity.shared().keychain.write(NSKeyedArchiver.archivedData(withRootObject: passcode), toKeychainItemForAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
    }

    static func removePasscodeFromKeychain() {
        OCAppIdentity.shared().keychain.removeItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath)
    }

}
