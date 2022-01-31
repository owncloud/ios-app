//
//  LAContext+Extension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 09/05/2018.
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

import LocalAuthentication
import UIKit

extension LAContext {

    public func supportedBiometricsAuthenticationName() -> String? {
        if  canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            switch self.biometryType {
            case .faceID : return "Face ID".localized
            case .touchID: return "Touch ID".localized
            case .none: return nil
            }
        }
        return nil
	}

	public func biometricsAuthenticationImage() -> UIImage? {
		if  canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
			switch self.biometryType {
			case .faceID : if #available(iOSApplicationExtension 13.0, *) {
				return UIImage(systemName: "faceid")
			} else {
				return UIImage(named: "biometrical-faceid")
			}
			case .touchID: if #available(iOSApplicationExtension 13.0, *) {
				return UIImage(systemName: "touchid")
			} else {
				return UIImage(named: "biometrical-touchid")
			}
			case .none: return nil
			}
		}
		return nil
	}
}
