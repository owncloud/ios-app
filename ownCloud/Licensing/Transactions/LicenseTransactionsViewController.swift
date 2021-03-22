//
//  LicenseTransactionsViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.12.19.
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
import ownCloudApp
import ownCloudAppShared

class LicenseTransactionsViewController: StaticTableViewController {
	init() {
		super.init(style: .grouped)

		self.navigationItem.title = "Purchases".localized

		self.toolbarItems = [
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			UIBarButtonItem(title: "Restore purchases".localized, style: .plain, target: self, action: #selector(restorePurchases)),
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		]

		fetchTransactions()
	}

	func fetchTransactions() {
		OCLicenseManager.shared.retrieveAllTransactions(completionHandler: { (error, transactionsByProvider) in
			if let error = error {
				let alert = UIAlertController(title: "Error fetching transactions".localized, message: error.localizedDescription, preferredStyle: .alert)

				alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

				self.present(alert, animated: true, completion: nil)
			}

			if let transactionsByProvider = transactionsByProvider {
				self.generateContent(from: transactionsByProvider)
			}
		})
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationController?.toolbar.isTranslucent = false
		self.navigationController?.isToolbarHidden = false
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.navigationController?.isToolbarHidden = true
	}

	func generateContent(from transactionsByProvider : [[OCLicenseTransaction]]) {
		for transactions in transactionsByProvider {
			var firstTransaction = true

			let sortedTransactions = transactions.sorted { (t1, t2) in
				return (t1.date?.timeIntervalSinceReferenceDate ?? Double.greatestFiniteMagnitude) > (t2.date?.timeIntervalSinceReferenceDate ?? Double.greatestFiniteMagnitude)
			}

			for transaction in sortedTransactions {
				if let tableRows = transaction.displayTableRows, tableRows.count > 0 {
					let section = StaticTableViewSection(headerTitle: firstTransaction ? transaction.provider?.localizedName : nil)

					for tableRow in tableRows {
						for (label, value) in tableRow {
							section.add(row: StaticTableViewRow(valueRowWithAction: nil, title: label, value: value))
						}
					}

					if let links = transaction.links {
						for (title, url) in links {
							section.add(row: StaticTableViewRow(rowWithAction: { (_, _) in
								UIApplication.shared.open(url, options: [:], completionHandler: nil)
							}, title: title, alignment: .center))
						}
					}

					firstTransaction = false

					self.addSection(section)
				}
			}
		}
	}

	@objc func restorePurchases() {
		OCLicenseManager.shared.restorePurchases(on: self) { (error) in
			if error == nil {
				self.removeSections(self.sections)
				self.fetchTransactions()
			}
		}
	}
}
