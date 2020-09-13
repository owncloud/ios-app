//
//  CertificateManagementViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 22.08.18.
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
import ownCloudAppShared

open class CertificateManagementRow : StaticTableViewRow {
	var certificate : OCCertificate?
}

class CertificateManagementViewController: StaticTableViewController {
	override func viewDidLoad() {

		super.viewDidLoad()

		self.navigationItem.title = "Certificates".localized

		if let userAcceptedCertificates = OCCertificate.userAcceptedCertificates {
			let uacSection = StaticTableViewSection(headerTitle: "User-approved certificates".localized)

			for certificate in userAcceptedCertificates {
				var shortReason = "Approved".localized

				if let userAcceptedReason = certificate.userAcceptedReason {
					switch userAcceptedReason {
						case .autoAccepted:
							shortReason = "Auto-approved".localized

						case .userAccepted: break
						default: break
					}
				}

				let approvalDate = shortReason + " " + ((certificate.userAcceptedDate==nil) ? " \("undated".localized)" : DateFormatter.localizedString(from: certificate.userAcceptedDate!, dateStyle: .medium, timeStyle: .short))
				let certificateRow = CertificateManagementRow(subtitleRowWithAction: { (row, _) in
					if let certificateDetailsViewController = ThemeCertificateViewController(certificate: certificate) {
						row.viewController?.navigationController?.pushViewController(certificateDetailsViewController, animated: true)
					}
				}, title: certificate.hostName ?? "", subtitle: approvalDate, accessoryType: .disclosureIndicator)

				certificateRow.certificate = certificate

				uacSection.add(row: certificateRow)
			}

			self.addSection(uacSection)
		}
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return UISwipeActionsConfiguration(actions: [UIContextualAction(style: .destructive, title: "Revoke approval".localized, handler: { [weak self] (_, _, completionHandler) in
			if let certificateRow = self?.staticRowForIndexPath(indexPath) as? CertificateManagementRow {
				certificateRow.certificate?.userAccepted = false

				certificateRow.section?.remove(rows: [certificateRow], animated: true)

				if (OCCertificate.userAcceptedCertificates?.count ?? 0) == 0 {
					self?.navigationController?.popViewController(animated: true)
				}
			}

			completionHandler(true)
		})])
	}
}
