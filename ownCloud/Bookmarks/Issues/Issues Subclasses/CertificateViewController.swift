//
//  CertificatesViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

class CertificateViewController: IssuesViewController {

	var localizedDescription: NSAttributedString? {
		didSet {
			if self.tableView?.window != nil {
				self.tableView?.reloadData()
			}
		}
	}

	init(buttons: [IssueButton]? = nil) {
		if buttons != nil {
			super.init(buttons: buttons, title: "Certificate Details".localized)
		} else {
			super.init(buttons: nil, title: "Certificate Details".localized)
			self.buttons = [IssueButton(title: "OK".localized, type: .plain, action: {
				self.dismiss(animated: true)}, accessibilityIdentifier: "ok-button-certificate-details")]
		}
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView?.dataSource = self
	}
}

extension CertificateViewController: UITableViewDataSource {

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel?.attributedText = localizedDescription
		cell.textLabel?.numberOfLines = 0
		cell.selectionStyle = .none
		return cell
	}
}
