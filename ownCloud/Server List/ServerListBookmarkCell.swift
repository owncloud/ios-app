//
//  ServerListBookmarkCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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
import ownCloudApp
import ownCloudAppShared

class ServerListBookmarkCell : ThemeTableViewCell {
	static private let iconSideLength : CGFloat = 40

	public var titleLabel : UILabel = UILabel()
	public var detailLabel : UILabel = UILabel()
	public var logoFallbackView : UIImageView = UIImageView()
	public var iconView : ResourceViewHost = ResourceViewHost(fallbackSize: CGSize(width: ServerListBookmarkCell.iconSideLength, height: ServerListBookmarkCell.iconSideLength))
	public var infoView : UIView = UIView()

	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func prepareViewAndConstraints() {
		self.selectionStyle = .default

		PointerEffect.install(on: self.contentView, effectStyle: .hover)

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		iconView.translatesAutoresizingMaskIntoConstraints = false
		logoFallbackView.translatesAutoresizingMaskIntoConstraints = false
		infoView.translatesAutoresizingMaskIntoConstraints = false

		logoFallbackView.contentMode = .scaleAspectFit
		logoFallbackView.image = Branding.shared.brandedImageNamed(.bookmarkIcon)

		iconView.fallbackView = logoFallbackView

		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		titleLabel.adjustsFontForContentSizeCategory = true

		detailLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
		detailLabel.adjustsFontForContentSizeCategory = true

		detailLabel.textColor = UIColor.gray

		contentView.addSubview(titleLabel)
		contentView.addSubview(detailLabel)
		contentView.addSubview(iconView)
		contentView.addSubview(infoView)

		NSLayoutConstraint.activate([
			iconView.widthAnchor.constraint(equalToConstant: ServerListBookmarkCell.iconSideLength),
			iconView.heightAnchor.constraint(equalToConstant: ServerListBookmarkCell.iconSideLength),
			iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

			iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -25),
			iconView.trailingAnchor.constraint(equalTo: detailLabel.leadingAnchor, constant: -25),

			titleLabel.trailingAnchor.constraint(equalTo: infoView.leadingAnchor),
			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
			titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5),

			detailLabel.trailingAnchor.constraint(equalTo: infoView.leadingAnchor),
			detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

			infoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
			infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
			infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
		])

		infoView.setContentHuggingPriority(.required, for: .horizontal)
		logoFallbackView.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

		Theme.shared.add(tvgResourceFor: "owncloud-logo")

		NotificationCenter.default.addObserver(self, selector: #selector(ServerListBookmarkCell.updateMessageBadgeFrom(notification:)), name: .BookmarkMessageCountChanged, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .BookmarkMessageCountChanged, object: nil)
	}

	// MARK: - Content updates
	var messageSelector : MessageSelector?
	var directMessageCountTrackingEnabled : Bool = false
	var bookmark : OCBookmark? {
		didSet {
			if let bookmark = bookmark {
				titleLabel.text = bookmark.shortName
				detailLabel.text = bookmark.url?.absoluteString
				accessibilityIdentifier = "server-bookmark-cell"

				iconView.activeViewProvider = bookmark.avatar

				if directMessageCountTrackingEnabled {
					messageSelector = MessageSelector(from: .global, filter: { (message) -> Bool in
						return (message.bookmarkUUID == bookmark.uuid) && !message.resolved
					}, handler: { [weak self] (messages, _, _) in
						OnMainThread {
							self?.updateMessageBadge(count: (messages != nil) ? messages!.count : 0)
						}
					})
				}
			} else {
				if directMessageCountTrackingEnabled {
					messageSelector = nil
				}
			}
		}
	}

	// MARK: - Message Badge
	private var badgeLabel : RoundedLabel?

	func updateMessageBadge(count: Int) {
		if count > 0 {
			if badgeLabel == nil {
				badgeLabel = RoundedLabel(text: "", style: .token)
				badgeLabel?.translatesAutoresizingMaskIntoConstraints = false

				if let badgeLabel = badgeLabel {
					infoView.addSubview(badgeLabel)

					NSLayoutConstraint.activate([
						badgeLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20),
						badgeLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),
						badgeLabel.centerYAnchor.constraint(equalTo: infoView.centerYAnchor)
					])
				}
			}

			badgeLabel?.labelText = "\(count)"
		} else {
			badgeLabel?.removeFromSuperview()
			badgeLabel = nil
		}
	}

	@objc func updateMessageBadgeFrom(notification: Notification) {
		if let countByBookmarkUUID = notification.object as? ServerListTableViewController.ServerListTableMessageCountByUUID, let bookmarkUUID = bookmark?.uuid {
			self.updateMessageBadge(count: countByBookmarkUUID[bookmarkUUID] ?? 0)
		}
	}

	// MARK: - Themeing
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
		if !VendorServices.shared.isBranded {
			self.logoFallbackView.image = self.logoFallbackView.image?.tinted(with: collection.tableRowColors.labelColor)
		}
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		let itemState = ThemeItemState(selected: self.isSelected)

		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
		if !VendorServices.shared.isBranded {
			self.logoFallbackView.image = self.logoFallbackView.image?.tinted(with: collection.tableRowColors.labelColor)
		}
	}
}
