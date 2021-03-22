//
//  OCCertificate+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 19.03.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import UIKit
import ownCloudSDK
import ownCloudAppShared

extension OCCertificate {

	func validationResult(completionHandler: @escaping (_ status: OCCertificateValidationResult, _ shortDescription : String, _ longDescription : String, _ color : UIColor, _ error : Error) -> Void) {

		self.evaluate(completionHandler: { (_, status, error) in
			var color = UIColor.red
			var shortDescription = ""
			var longDescription = ""

			switch status {

			case .none:
				break
			case .error:
				color = Theme.shared.activeCollection.errorColor
				shortDescription = "Error".localized
				longDescription = "\("Validation Error".localized) \(error.localizedDescription)"
			case .reject:
				color = Theme.shared.activeCollection.errorColor
				shortDescription = "Rejected".localized
				longDescription = "Certificate was rejected by user.".localized
			case .promptUser:
				color = Theme.shared.activeCollection.warningColor
				shortDescription = "Warning".localized
				longDescription = "Certificate has issues.\nOpen 'Certificate Details' for more informations.".localized
			case .passed:
				color = Theme.shared.activeCollection.successColor
				shortDescription = "Passed".localized
				longDescription = "No issues found. Certificate passed validation.".localized
			case .userAccepted:
				color = Theme.shared.activeCollection.warningColor
				shortDescription = "Accepted".localized
				longDescription = "Certificate may have issues, but was accepted by user.\nOpen 'Certificate Details' for more informations.".localized
			}
			completionHandler(status, shortDescription, longDescription, color, error)
		})
	}
}
