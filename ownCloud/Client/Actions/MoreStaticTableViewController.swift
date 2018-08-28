//
//  MoreStaticTableViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/08/2018.
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

class MoreStaticTableViewController: StaticTableViewController {

	private var themeApplierTokens: [ThemeApplierToken]

	override init(style: UITableViewStyle) {
		themeApplierTokens = []
		super.init(style: style)
	}

	deinit {
		themeApplierTokens.forEach({
			Theme.shared.remove(applierForToken: $0)
		})
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if let title = sections[section].headerAttributedTitle {
			let containerView = UIView()
			let label = UILabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(label)
			NSLayoutConstraint.activate([
				label.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 32),
				label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
				label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
				label.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -32)
				])

			label.attributedText = title

			let messageApplierToken = Theme.shared.add(applier: { (_, collection, _) in
				label.applyThemeCollection(collection)
			})

			themeApplierTokens.append(messageApplierToken)

			return containerView
		}

		return nil
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
		self.tableView.separatorColor = self.tableView.backgroundColor
	}
}
