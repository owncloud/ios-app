//
//  DriveGridCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension UIAction.Identifier {
	static let ocMoreAction = UIAction.Identifier(rawValue: "ocMoreAction")
}

class DriveGridCell: DriveHeaderCell {
	var moreButton: UIButton = UIButton()
	var moreAction: OCAction? {
		didSet {
			configureMoreButton()
		}
	}

	var moreMenu: UIMenu? {
		didSet {
			configureMoreButton()
		}
	}

	func configureMoreButton() {
		// Reset state
		moreButton.removeAction(identifiedBy: .ocMoreAction, for: .primaryActionTriggered)
		moreButton.menu = nil
		moreButton.showsMenuAsPrimaryAction = false
		moreButton.isHidden = true
		accessibilityCustomActions = nil

		if let moreAction {
			moreButton.addAction(UIAction(identifier: .ocMoreAction, handler: { [weak self] _ in
				self?.moreAction?.run()
			}), for: .primaryActionTriggered)

			moreButton.isHidden = false
			accessibilityCustomActions = [ moreAction.accessibilityCustomAction() ]
		}

		if let moreMenu {
			moreButton.menu = moreMenu
			moreButton.showsMenuAsPrimaryAction = true

			moreButton.isHidden = false
		}
	}

	private var disabledLabel: UIView?
	var isDisabled: Bool = false {
		didSet {
			if isDisabled == oldValue { return }

			// Remove disabled label (if any)
			disabledLabel?.removeFromSuperview()
			disabledLabel = nil

			if isDisabled {
				// Create and add disabled label
				disabledLabel = ComposedMessageView.infoBox(image: nil, title: OCLocalizedString("Disabled", nil), withRoundedBackgroundView: true)
				if let disabledLabel {
					embed(centered: disabledLabel)
				}
			}
		}
	}

	override var suggestedCellHeight: CGFloat? {
		return nil
	}

	override func configure() {
		super.configure()

		contentView.layer.cornerRadius = 8
		titleLabel.numberOfLines = 1
		titleLabel.lineBreakMode = .byTruncatingTail
		subtitleLabel.numberOfLines = 1
		subtitleLabel.lineBreakMode = .byTruncatingTail

		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10)
		var buttonConfig = UIButton.Configuration.filled()
		buttonConfig.image = UIImage(systemName: "ellipsis", withConfiguration: symbolConfig)
		buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
		buttonConfig.buttonSize = .mini
		buttonConfig.cornerStyle = .capsule

		moreButton.configuration = buttonConfig
		moreButton.translatesAutoresizingMaskIntoConstraints = false
		moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
		configureMoreButton()

		titleLabel.isAccessibilityElement = false
		subtitleLabel.isAccessibilityElement = false
		isAccessibilityElement = true
		accessibilityTraits = .button

		contentView.addSubview(moreButton)
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		self.cssSelectors = state.isFocused ? [.header, .drive, .focused] : [.header, .drive]
		applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .update)
	}

	override func configureLayout() {
		super.configureLayout()

		moreButton.setContentHuggingPriority(.required, for: .horizontal)

		NSLayoutConstraint.activate([
			titleLabel.centerYAnchor.constraint(equalTo: moreButton.centerYAnchor),
			titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -10),
			moreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
		])
	}

	override var title: String? {
		didSet {
			accessibilityLabel = title?.redacted()
		}
	}

	override var subtitle: String? {
		didSet {
			subtitleLabel.text = subtitle?.redacted() ?? " " // Ensure the grid cells' titles align by always showing a subtitle - if necessary, an empty one
			accessibilityHint = subtitle?.redacted()
		}
	}

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		super.applyThemeCollectionToCellContents(theme: theme, collection: collection, state: state)

		darkBackgroundView.applyThemeCollection(theme: theme, collection: collection, event: .update)
		moreButton.apply(css: collection.css, properties: [.stroke, .fill])
	}
}
