//
//  ReleaseNotesTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 09.10.19.
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

class ReleaseNotesTableViewController: StaticTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		let header = UILabel()
		header.text = "New in ownCloud"
		header.translatesAutoresizingMaskIntoConstraints = false


		NSLayoutConstraint.activate([
			header.heightAnchor.constraint(equalToConstant: 100.0)
			])

	//	self.tableView.tableHeaderView = header

		let row = StaticTableViewRow(rowWithAction: nil, title: "Scan documents", subtitle: "Scan documents with iOS 13 with your camera and save it as PDF, JPEG or PNG direclty in your ownCloud account.", image: UIImage(named: "available-offline"), imageWidth: 50, alignment: .left, accessoryType: .none)

		let section = StaticTableViewSection(headerTitle: "New in ownCloud")
		section.add(row: row)

		let buttonRow = StaticTableViewRow(buttonWithAction: { (_, _) in
			self.dismissAnimated()
		}, title: "Proceed", style: .proceed, image: nil, imageWidth: nil, alignment: .center, identifier: nil, accessoryView: nil)
		//section.add(row: buttonRow)
		self.addSection(section)



		/*

		let containerInsets = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
		let messageProgressSpacing : CGFloat = 15
		let progressCancelSpacing : CGFloat = 25
		let containerView = UIView()



		let proceedButton = ThemeButton()
		proceedButton.setTitle("Proceed".localized, for: .normal)
		proceedButton.backgroundColor = UIColor.red
		containerView.translatesAutoresizingMaskIntoConstraints = false
		proceedButton.translatesAutoresizingMaskIntoConstraints = false

		containerView.addSubview(proceedButton)

		NSLayoutConstraint.activate([
			proceedButton.heightAnchor.constraint(equalToConstant: 40),
			proceedButton.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 50),
		proceedButton.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -50),

		containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: containerInsets.top),
		containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -containerInsets.bottom),
		containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: containerInsets.left),
		containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -containerInsets.right)
			])

		self.tableView.tableFooterView = containerView

		self.tableView.separatorStyle = .none*/
    }

	
}
