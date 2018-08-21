//
//  MoreViewHeader.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

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
		detailLabel.attributedText =  NSAttributedString(string: size, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])

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
