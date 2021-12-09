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
	private var labelContainerView : UIView
	private var titleLabel: UILabel
	private var detailLabel: UILabel
	private var favoriteButton: UIButton
	var activityIndicator : UIActivityIndicatorView
	private var showsIcon : Bool = true

	var thumbnailSize = CGSize(width: 60, height: 60)
	let favoriteSize = CGSize(width: 44, height: 44)

	var showFavoriteButton: Bool
	var showActivityIndicator: Bool
	var adaptBackgroundColor : Bool

	var item: OCItem
	weak var core: OCCore?
	var url: URL?

	init(for item: OCItem, with core: OCCore, favorite: Bool = true, adaptBackgroundColor: Bool = false, showActivityIndicator: Bool = false) {
		self.item = item
		self.core = core
		self.showFavoriteButton = favorite
		self.showActivityIndicator = showActivityIndicator

		iconView = UIImageView()
		titleLabel = UILabel()
		detailLabel = UILabel()
		labelContainerView = UIView()
		favoriteButton = UIButton()
		activityIndicator = UIActivityIndicatorView(style: .white)
		self.adaptBackgroundColor = adaptBackgroundColor

		super.init(frame: .zero)

		self.translatesAutoresizingMaskIntoConstraints = false

		Theme.shared.register(client: self)

		render()
	}

	init(url : URL) {
		self.showFavoriteButton = false
		self.showActivityIndicator = false
		self.adaptBackgroundColor = false
		self.item = OCItem()
		self.url = url

		iconView = UIImageView()
		titleLabel = UILabel()
		detailLabel = UILabel()
		labelContainerView = UIView()
		favoriteButton = UIButton()
		activityIndicator = UIActivityIndicatorView(style: .white)

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
		labelContainerView.translatesAutoresizingMaskIntoConstraints = false
		favoriteButton.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		iconView.contentMode = .scaleAspectFit

		titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
		detailLabel.font = UIFont.systemFont(ofSize: 14)

		labelContainerView.addSubview(titleLabel)
		labelContainerView.addSubview(detailLabel)

		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		labelContainerView.setContentCompressionResistancePriority(.required, for: .vertical)

		NSLayoutConstraint.activate([
			titleLabel.leftAnchor.constraint(equalTo: labelContainerView.leftAnchor),
			titleLabel.rightAnchor.constraint(equalTo: labelContainerView.rightAnchor),
			titleLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor),

			detailLabel.leftAnchor.constraint(equalTo: labelContainerView.leftAnchor),
			detailLabel.rightAnchor.constraint(equalTo: labelContainerView.rightAnchor),
			detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
			detailLabel.bottomAnchor.constraint(equalTo: labelContainerView.bottomAnchor)
		])

		self.addSubview(iconView)
		self.addSubview(labelContainerView)

		NSLayoutConstraint.activate([
			iconView.widthAnchor.constraint(equalToConstant: thumbnailSize.width),
			iconView.heightAnchor.constraint(equalToConstant: thumbnailSize.height),

			iconView.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor, constant: 20),
			iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
			iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).with(priority: .defaultHigh),

			labelContainerView.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 15),
			labelContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
			labelContainerView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 20),
			labelContainerView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -20).with(priority: .defaultHigh)
		])

		if showFavoriteButton {
			updateFavoriteButtonImage()
			favoriteButton.addTarget(self, action: #selector(toogleFavoriteState), for: UIControl.Event.touchUpInside)
			self.addSubview(favoriteButton)
			if #available(iOS 13.4, *) {
				favoriteButton.isPointerInteractionEnabled = true
			}

			NSLayoutConstraint.activate([
				favoriteButton.widthAnchor.constraint(equalToConstant: favoriteSize.width),
				favoriteButton.heightAnchor.constraint(equalToConstant: favoriteSize.height),
				favoriteButton.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor, constant: -15),
				favoriteButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				favoriteButton.leftAnchor.constraint(equalTo: labelContainerView.rightAnchor, constant: 10)
				])
		} else if showActivityIndicator {
			self.addSubview(activityIndicator)

			NSLayoutConstraint.activate([
				activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				activityIndicator.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor, constant: -15),
				activityIndicator.leftAnchor.constraint(equalTo: labelContainerView.rightAnchor, constant: 10)
				])
		} else {
			NSLayoutConstraint.activate([
				labelContainerView.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor, constant: -20)
			])
		}

		if let url = url {
			titleLabel.attributedText = NSAttributedString(string: url.lastPathComponent, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])

			do {
				let attr = try FileManager.default.attributesOfItem(atPath: url.path)

				if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
					let byteCountFormatter = ByteCountFormatter()
					byteCountFormatter.countStyle = .file
					let size = byteCountFormatter.string(fromByteCount: Int64(fileSize))

					detailLabel.attributedText =  NSAttributedString(string: size, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular)])
				}
			} catch {
				print("Error: \(error)")
			}
		} else {
			titleLabel.attributedText = NSAttributedString(string: item.name ?? "", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])

			let byteCountFormatter = ByteCountFormatter()
			byteCountFormatter.countStyle = .file
			var size = byteCountFormatter.string(fromByteCount: Int64(item.size))

			if item.size < 0 {
				size = "Pending".localized
			}

			let dateString = item.lastModifiedLocalized

			let detail = size + " - " + dateString

			detailLabel.attributedText =  NSAttributedString(string: detail, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular)])
		}

		self.iconView.image = item.icon(fitInSize: CGSize(width: thumbnailSize.width, height: thumbnailSize.height))

		if item.thumbnailAvailability != .none {
			let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
				_ = thumbnail?.requestImage(for: CGSize(width: self.thumbnailSize.width, height: self.thumbnailSize.height), scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
					if error == nil,
						image != nil,
						self.item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
						OnMainThread {
							self.showsIcon = false
							self.iconView.image = image
						}
					}
				})
			}

			_ = core?.retrieveThumbnail(for: item, maximumSize: CGSize(width: self.thumbnailSize.width, height: self.thumbnailSize.height), scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, _) in
				displayThumbnail(thumbnail)
			})
		}
		titleLabel.numberOfLines = 0
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func toogleFavoriteState() {
		if item.isFavorite == true {
			item.isFavorite = false
		} else {
			item.isFavorite = true
		}
		self.updateFavoriteButtonImage()
		core?.update(item, properties: [OCItemPropertyName.isFavorite], options: nil, resultHandler: { (error, _, _, _) in
			if error == nil {
				OnMainThread {
					self.updateFavoriteButtonImage()
				}
			}
		})
	}

	func updateFavoriteButtonImage() {
		if item.isFavorite == true {
			favoriteButton.setImage(UIImage(named: "star"), for: .normal)
			favoriteButton.tintColor = Theme.shared.activeCollection.favoriteEnabledColor
		} else {
			favoriteButton.setImage(UIImage(named: "unstar"), for: .normal)
			favoriteButton.tintColor = Theme.shared.activeCollection.favoriteDisabledColor
		}
	}
}

extension MoreViewHeader: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		titleLabel.applyThemeCollection(collection)
		detailLabel.applyThemeCollection(collection, itemStyle: .message)
		activityIndicator.style = collection.activityIndicatorViewStyle

		if adaptBackgroundColor {
			backgroundColor = collection.tableBackgroundColor
		}

		if showsIcon {
			iconView.image = item.icon(fitInSize: CGSize(width: thumbnailSize.width, height: thumbnailSize.height))
		}
	}
}
