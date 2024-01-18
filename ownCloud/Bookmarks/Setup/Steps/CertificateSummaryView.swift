//
//  CertificateSummaryView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.09.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp
import ownCloudAppShared

class CertificateSummaryView: ThemeCSSView {
	init(with certificate: OCCertificate?, httpHostname: String?) {
		super.init()

		cssSelector = .certificateSummary

		button.translatesAutoresizingMaskIntoConstraints = false
		embed(toFillWith: button)

		button.addAction(UIAction(handler: { [weak self] _ in
			self?.showCertificate()
		}), for: .primaryActionTriggered)

		OnMainThread {
			self.httpHostname = httpHostname
			self.certificate = certificate

			self.update()
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var certificate: OCCertificate? {
		didSet {
			if let certificate {
				certificate.validationResult(completionHandler: { (validationResult, shortDescription, _, color, _) in
					OnMainThread {
						self.validationResult = validationResult
						self.statusText = shortDescription
						self.statusColor = color

						self.update()
					}
				})
			} else {
				OnMainThread {
					self.validationResult = nil
					self.statusText = nil
					self.statusColor = .systemRed

					self.update()
				}
			}
		}
	}

	var httpHostname: String?

	var button: UIButton = UIButton()

	var validationResult: OCCertificateValidationResult?
	var statusText: String?
	var statusColor: UIColor?

	var statusImage: UIImage? {
		var imageName: String?

		if certificate != nil {
			if let validationResult {

				switch validationResult {
					case .none, .error, .reject, .promptUser:
						imageName = "lock.slash.fill"

					case .passed:
						imageName = "lock.fill"

					case .userAccepted:
						imageName = "exclamationmark.lock.fill"
				}
			}
		} else {
			imageName = "lock.open.fill"
		}

		if let imageName {
			return UIImage.init(systemName: imageName)
		}

		return nil
	}

	func update() {
		var buttonConfiguration : UIButton.Configuration = .borderless()
		buttonConfiguration.baseForegroundColor = statusColor
		buttonConfiguration.baseBackgroundColor = .clear
		buttonConfiguration.image = self.statusImage
		buttonConfiguration.title = certificate?.hostName ?? httpHostname
		buttonConfiguration.buttonSize = .mini

		button.configuration = buttonConfiguration
	}

	func showCertificate() {
		if let certificate {
			let certificateViewController : ThemeCertificateViewController = ThemeCertificateViewController(certificate: certificate, compare: nil)
			let navigationController = ThemeNavigationController(rootViewController: certificateViewController)

			hostingViewController?.present(navigationController, animated: true, completion: nil)
		}
	}
}
