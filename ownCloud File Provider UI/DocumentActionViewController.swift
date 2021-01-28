//
//  DocumentActionViewController.swift
//  ownCloud File Provider UI
//
//  Created by Matthias Hühne on 28.01.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2021, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import FileProviderUI
import ownCloudApp
import ownCloudAppShared

class DocumentActionViewController: FPUIActionExtensionViewController {

    override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
    }

    override func prepare(forError error: Error) {
		AppLockManager.shared.passwordViewHostViewController = self
		AppLockManager.shared.cancelAction = { [weak self] in
			self?.extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
		}
		AppLockManager.shared.successAction = { [weak self] in
			self?.extensionContext.completeRequest()
		}

		AppLockManager.shared.showLockscreenIfNeeded()
    }

}
