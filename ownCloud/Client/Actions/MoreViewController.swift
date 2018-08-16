//
//  MoreViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 25/07/2018.
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

class MoreViewHeader: UIView {
	private var iconView: UIImageView
	private var titleLabel: UILabel
	private var detailLabel: UILabel

	var item: OCItem
	weak var core: OCCore?

	init(for item: OCItem, with core: OCCore) {
		self.item = item
		self.core = core

		iconView = UIImageView()
		titleLabel = UILabel()
		detailLabel = UILabel()
		super.init(frame: .zero)

		render()
	}

	private func render() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		iconView.translatesAutoresizingMaskIntoConstraints = false
		iconView.contentMode = .scaleAspectFit

		titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
		detailLabel.font = UIFont.systemFont(ofSize: 14)

		detailLabel.textColor = UIColor.gray

		self.addSubview(titleLabel)
		self.addSubview(detailLabel)
		self.addSubview(iconView)

		iconView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
		iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -15).isActive = true
		iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -15).isActive = true

		titleLabel.rightAnchor.constraint(equalTo:  self.rightAnchor, constant: -20).isActive = true
		detailLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true

		iconView.widthAnchor.constraint(equalToConstant: 60).isActive = true
		iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

		titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
		titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5).isActive = true
		detailLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true

		iconView.setContentHuggingPriority(UILayoutPriority.required, for: UILayoutConstraintAxis.vertical)
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
		detailLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)

		titleLabel.attributedText = NSAttributedString(string: item.name, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])
		detailLabel.attributedText =  NSAttributedString(string: item.name, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])

		self.iconView.image = item.icon(fitInSize: CGSize(width: 40, height: 40))

		if item.thumbnailAvailability != .none {
			let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
				_ = thumbnail?.requestImage(for: CGSize(width: 60, height: 60), scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
					if error == nil,
						image != nil,
						self.item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
						OnMainThread {
							self.iconView.image = image
						}
					}
				})
			}

			_ = core?.retrieveThumbnail(for: item, maximumSize: CGSize(width: 150, height: 150), scale: 0, retrieveHandler: { (error, _, _, thumbnail, _, progress) in
				displayThumbnail(thumbnail)
			})
		}
		titleLabel.numberOfLines = 0
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class MoreViewController: UIViewController {

	private var item: OCItem
	private var core: OCCore

	private var headerView: UIView
	private var viewController: UIViewController

	init(item: OCItem, core: OCCore, header: UIView, viewController: UIViewController) {
		self.item = item
		self.core = core
		self.headerView = header
		self.viewController = viewController

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		definesPresentationContext = true

		Theme.shared.register(client: self)

		headerView.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(headerView)
		NSLayoutConstraint.activate([
			headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
			headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
			headerView.topAnchor.constraint(equalTo: view.topAnchor),
			headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
			])

		view.addSubview(viewController.view)
		viewController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			viewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
			viewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
			viewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
			viewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)
			])

		headerView.layer.shadowColor = UIColor.black.cgColor
		headerView.layer.shadowOpacity = 0.1
		headerView.layer.shadowRadius = 10
		headerView.layer.cornerRadius = 10
		headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

		// Drag view
		let dragView: UIView = UIView()
		dragView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(dragView)
		dragView.layer.cornerRadius = 2.5

		NSLayoutConstraint.activate([
			dragView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
			dragView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			dragView.widthAnchor.constraint(equalToConstant: 50),
			dragView.heightAnchor.constraint(equalToConstant: 5)
			])
		dragView.backgroundColor = .lightGray
	}
}

extension MoreViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.headerView.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
	}
}

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
