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
			let css = Theme.shared.activeCollection.css

			switch status {

				case .none:
					break
				case .error:
					color = css.getColor(.stroke, selectors: [.error], for: nil) ?? .systemRed // Theme.shared.activeCollection.errorColor
					shortDescription = OCLocalizedString("Error", nil)
					longDescription = "\(OCLocalizedString("Validation Error", nil)) \(error.localizedDescription)"
				case .reject:
					color = css.getColor(.stroke, selectors: [.error], for: nil) ?? .systemRed // Theme.shared.activeCollection.errorColor
					shortDescription = OCLocalizedString("Rejected", nil)
					longDescription = OCLocalizedString("Certificate was rejected by user.", nil)
				case .promptUser:
					color = css.getColor(.stroke, selectors: [.warning], for: nil) ?? .systemYellow
					shortDescription = OCLocalizedString("Warning", nil)
					longDescription = OCLocalizedString("Certificate has issues.\nOpen 'Certificate Details' for more informations.", nil)
				case .passed:
					color = css.getColor(.stroke, selectors: [.success], for: nil) ?? .systemGreen
					shortDescription = OCLocalizedString("Passed", nil)
					longDescription = OCLocalizedString("No issues found. Certificate passed validation.", nil)
				case .userAccepted:
					color = css.getColor(.stroke, selectors: [.warning], for: nil) ?? .systemYellow
					shortDescription = OCLocalizedString("Accepted", nil)
					longDescription = OCLocalizedString("Certificate may have issues, but was accepted by user.\nOpen 'Certificate Details' for more informations.", nil)
			}
			completionHandler(status, shortDescription, longDescription, color, error)
		})
	}
}
