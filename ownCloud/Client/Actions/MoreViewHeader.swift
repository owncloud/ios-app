//
//  MoreViewHeader.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

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

		self.translatesAutoresizingMaskIntoConstraints = false

		Theme.shared.register(client: self)

		render()
	}

	deinit {
		Theme.shared.unregister(client: self)
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

		iconView.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor, constant: 32).isActive = true
		iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -15).isActive = true
		iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -15).isActive = true

		titleLabel.rightAnchor.constraint(equalTo:  self.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
		detailLabel.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true

		iconView.widthAnchor.constraint(equalToConstant: 60).isActive = true
		iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

		titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
		titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5).isActive = true
		detailLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true

		iconView.setContentHuggingPriority(UILayoutPriority.required, for: UILayoutConstraintAxis.vertical)
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
		detailLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)

		titleLabel.attributedText = NSAttributedString(string: item.name, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])

		let bcf = ByteCountFormatter()
		bcf.countStyle = .file
		let size = bcf.string(fromByteCount: Int64(item.size))

		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .none
		dateFormatter.dateStyle = .medium
		dateFormatter.locale = Locale.current
		dateFormatter.doesRelativeDateFormatting = true

		let dateString = dateFormatter.string(from: item.lastModified)

		let detail = size + " - " + dateString

		detailLabel.attributedText =  NSAttributedString(string: detail, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .regular)])

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

			_ = core?.retrieveThumbnail(for: item, maximumSize: CGSize(width: 150, height: 150), scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, _) in
				displayThumbnail(thumbnail)
			})
		}
		titleLabel.numberOfLines = 0
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension MoreViewHeader: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.titleLabel.applyThemeCollection(collection)
		self.detailLabel.applyThemeCollection(collection)
	}
}
