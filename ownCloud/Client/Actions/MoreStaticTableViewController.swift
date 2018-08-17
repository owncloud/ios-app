//
//  MoreStaticTableViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class MoreStaticTableViewController: StaticTableViewController {

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if let title = sections[section].headerAttributedTitle {
			let containerView = UIView()
			let label = UILabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(label)
			NSLayoutConstraint.activate([
				label.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 32),
				label.topAnchor.constraint(equalTo: containerView.topAnchor),
				label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
				label.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -32)
				])

			label.attributedText = title
			return containerView
		}

		return nil
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section != 0 {
			return 56
		}

		return UITableViewAutomaticDimension
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if sections[section].headerAttributedTitle != nil || sections[section].headerTitle != nil {
			return 56
		}

		return 0
	}

	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if sections[section].footerAttributedTitle != nil || sections[section].footerTitle != nil {
			return 56
		}

		return 0
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
		self.tableView.separatorColor = self.tableView.backgroundColor
	}
}
