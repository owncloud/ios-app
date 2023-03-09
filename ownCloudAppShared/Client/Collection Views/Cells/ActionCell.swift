//
//  ActionCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 30.05.22.
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

class ActionCell: ThemeableCollectionViewCell {
	public enum Style : CaseIterable {
		case vertical
		case horizontal
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
		configureLayout()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	let iconView = UIImageView()
	let titleLabel = UILabel()

	var iconInsets : UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
	var titleInsets : UIEdgeInsets = UIEdgeInsets(top: 5, left: 3, bottom: 5, right: 3)

	var title : String? {
		didSet {
			titleLabel.text = title
		}
	}
	var icon : UIImage? {
		didSet {
			iconView.image = icon
		}
	}
	var type : OCActionType = .regular {
		didSet {
			if superview != nil {
				applyThemeCollectionToCellContents(theme: Theme.shared, collection: Theme.shared.activeCollection, state: .normal)
			}
		}
	}
	var style: Style = .vertical {
		didSet {
			if oldValue != style {
				configureLayout()
			}
		}
	}

	func configure() {
		iconView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false

		contentView.addSubview(titleLabel)
		contentView.addSubview(iconView)

		iconView.image = icon
		iconView.contentMode = .scaleAspectFit

		titleLabel.setContentHuggingPriority(.required, for: .vertical)
//		titleLabel.setContentHuggingPriority(.required, for: .horizontal)

		titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		titleLabel.lineBreakMode = .byWordWrapping
		titleLabel.numberOfLines = 1

		iconView.setContentHuggingPriority(.required, for: .horizontal)

		let backgroundConfig = UIBackgroundConfiguration.clear()
		backgroundConfiguration = backgroundConfig
	}

	func configureLayout() {
		switch style {
			case .vertical:
				iconInsets = UIEdgeInsets(top: 6, left: 7, bottom: 0, right: 7)
				titleInsets = UIEdgeInsets(top: 5, left: 7, bottom: 6, right: 7)

				titleLabel.textAlignment = .center

				titleLabel.font = UIFont.systemFont(ofSize: 10)

				self.configuredConstraints = [
					iconView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: iconInsets.left),
					iconView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -iconInsets.right),
					iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
					iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: iconInsets.top),
					iconView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -(iconInsets.bottom + titleInsets.top)),

					titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: titleInsets.left),
					titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -titleInsets.right),
					titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
					titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -titleInsets.bottom)
				]

			case .horizontal:
				iconInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 5)
				titleInsets = UIEdgeInsets(top: 13, left: 3, bottom: 13, right: 10)

				titleLabel.textAlignment = .left

				titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
				titleLabel.adjustsFontForContentSizeCategory = true

				self.configuredConstraints = [
					iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: iconInsets.left),
					iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -(iconInsets.right + titleInsets.left)),
					iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: iconInsets.top),
					iconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -iconInsets.bottom),

					iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),

					titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -titleInsets.right),
					titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: titleInsets.top),
					titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -titleInsets.bottom)
				]
		}
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		let collection = Theme.shared.activeCollection
		var backgroundConfig = backgroundConfiguration?.updated(for: state)

		if state.isHighlighted || state.isSelected || (state.cellDropState == .targeted) {
			switch type {
				case .regular:
					backgroundConfig?.backgroundColor = UIColor(white: 0, alpha: 0.10)
				case .warning:
					backgroundConfig?.backgroundColor = collection.warningColors.highlighted.background
				case .destructive:
					backgroundConfig?.backgroundColor = collection.destructiveColors.highlighted.background
			}
		} else {
			switch type {
				case .regular:
					backgroundConfig?.backgroundColor = UIColor(white: 0, alpha: 0.05)
				case .warning:
					backgroundConfig?.backgroundColor = collection.warningColors.normal.background
				case .destructive:
					backgroundConfig?.backgroundColor = collection.destructiveColors.normal.background
			}
		}

		backgroundConfig?.cornerRadius = 8

		backgroundConfiguration = backgroundConfig
	}

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		super.applyThemeCollectionToCellContents(theme: theme, collection: collection, state: state)

		switch type {
			case .regular:
				titleLabel.textColor = collection.tintColor
				iconView.tintColor = collection.tintColor

			case .warning:
				titleLabel.textColor = collection.warningColors.normal.foreground
				iconView.tintColor = collection.warningColors.normal.foreground

			case .destructive:
				titleLabel.textColor = collection.destructiveColors.normal.foreground
				iconView.tintColor = collection.destructiveColors.normal.foreground
		}

		titleLabel.textColor = (type == .destructive) ? collection.destructiveColors.normal.foreground : collection.tintColor
		iconView.tintColor = (type == .destructive) ? collection.destructiveColors.normal.foreground : collection.tintColor

		setNeedsUpdateConfiguration()
	}
}


class ActionListCell: UICollectionViewListCell, Themeable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        Theme.shared.register(client: self, applyImmediately: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        Theme.shared.unregister(client: self)
    }
    
    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
        setNeedsUpdateConfiguration()
    }
    

    override func updateConfiguration(using state: UICellConfigurationState) {
        if var content = self.contentConfiguration as? UIListContentConfiguration {
            let collection = Theme.shared.activeCollection
            
            content.textProperties.color = collection.tableRowColors.labelColor
            content.imageProperties.tintColor =  collection.tintColor
            
            self.contentConfiguration = content
        }
    }
    
}

extension ActionCell {
	static func registerCellProvider() {
		let wideActionCellRegistration = UICollectionView.CellRegistration<ActionCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let action = OCDataRenderer.default.renderItem(item, asType: .action, error: nil, withOptions: nil) as? OCAction {
					cell.style = .horizontal
					cell.title = action.title
					cell.icon = action.icon
					cell.type = action.type
				}
			})
		}

		let gridActionCellRegistration = UICollectionView.CellRegistration<ActionCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let action = OCDataRenderer.default.renderItem(item, asType: .action, error: nil, withOptions: nil) as? OCAction {
					cell.style = .vertical
					cell.title = action.title
					cell.icon = action.icon
					cell.type = action.type
				}
			})
		}

		let actionSideBarCellRegistration = UICollectionView.CellRegistration<ActionListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
            
            
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				var accessories: [UICellAccessory] = []
				var content = cell.defaultContentConfiguration()
				var backgroundConfiguration: UIBackgroundConfiguration?

				if let action = item as? OCAction {
					content.text = action.title
					content.image = action.icon

					switch action.type {
						case .warning:
							content.textProperties.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .semibold)

							content.textProperties.color = Theme.shared.activeCollection.warningColors.normal.foreground
							content.imageProperties.tintColor = Theme.shared.activeCollection.warningColors.normal.foreground
							backgroundConfiguration = UIBackgroundConfiguration.listSidebarCell()
							backgroundConfiguration?.backgroundColor = Theme.shared.activeCollection.warningColors.normal.background

						case .destructive:
							content.textProperties.font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .semibold)

							content.textProperties.color = Theme.shared.activeCollection.destructiveColors.normal.foreground
							content.imageProperties.tintColor = Theme.shared.activeCollection.destructiveColors.normal.foreground
							backgroundConfiguration = UIBackgroundConfiguration.listSidebarCell()
							backgroundConfiguration?.backgroundColor = Theme.shared.activeCollection.destructiveColors.normal.background

                    default:
                        content.textProperties.color = Theme.shared.activeCollection.tableRowColors.labelColor
                        content.imageProperties.tintColor = Theme.shared.activeCollection.tintColor
                    }
                    

					if let buttonLabel = action.buttonLabel {
						let context = cellConfiguration.clientContext

						var buttonConfig = UIButton.Configuration.filled()
						buttonConfig.title = buttonLabel
						buttonConfig.buttonSize = .mini
						buttonConfig.cornerStyle = .capsule

						let button: UIButton = UIButton()
						button.configuration = buttonConfig
						button.addAction(UIAction(handler: { [weak action, weak context] _ in
							var options: [OCActionRunOptionKey:Any] = [:]

							if let context {
								options[.clientContext] = context
							}

							action?.run(options: options)
						}), for: .primaryActionTriggered)

						accessories.append(.customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing())))
					}
				}

				if let sidebarAction = item as? CollectionSidebarAction {
					if let badgeCount = sidebarAction.badgeCount {
						accessories.append(.customView(configuration: UICellAccessory.CustomViewConfiguration(customView: RoundedLabel(text: "\(badgeCount)", style: .token), placement: .trailing())))
					}
					if sidebarAction.childrenDataSource != nil {
						let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .cell)
						accessories.append(.outlineDisclosure(options: headerDisclosureOption))
					}
				}

//				if cellConfiguration.highlight {
//					if backgroundConfiguration == nil {
//						backgroundConfiguration = UIBackgroundConfiguration.listSidebarCell()
//						backgroundConfiguration?.backgroundColor = Theme.shared.activeCollection.darkBrandColor
//					}
//				}

				cell.accessories = accessories
				cell.contentConfiguration = content
				cell.backgroundConfiguration = backgroundConfiguration
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .action, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				case .gridCell:
					return collectionView.dequeueConfiguredReusableCell(using: gridActionCellRegistration, for: indexPath, item: itemRef)

				case .sideBar:
					return collectionView.dequeueConfiguredReusableCell(using: actionSideBarCellRegistration, for: indexPath, item: itemRef)

				default:
					return collectionView.dequeueConfiguredReusableCell(using: wideActionCellRegistration, for: indexPath, item: itemRef)
			}

		}))
	}
}
