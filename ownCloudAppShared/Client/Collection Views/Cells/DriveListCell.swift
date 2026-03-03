//
//  DriveCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 14.04.22.
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

class DriveListCell: ThemeableCollectionViewListCell {
	let coverImageResourceView = ResourceViewHost()
	let spaceFallbackImageView = UIImageView()

	let titleLabel = UILabel()
	let subtitleLabel = UILabel()

	lazy var moreButton: UIButton = {
		let moreButton = UIButton()
		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10)
		var buttonConfig = UIButton.Configuration.filled()
		buttonConfig.image = UIImage(systemName: "ellipsis", withConfiguration: symbolConfig)
		buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
		buttonConfig.buttonSize = .mini
		buttonConfig.cornerStyle = .capsule

		moreButton.configuration = buttonConfig
		moreButton.translatesAutoresizingMaskIntoConstraints = false
		moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
		moreButton.setContentHuggingPriority(.required, for: .horizontal)

		return moreButton
	}()
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

	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
		configureLayout()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	var textOuterSpacing : CGFloat = 10
	var textInterSpacing : CGFloat = 5

	var title : String? {
		didSet {
			titleLabel.text = title?.redacted()
		}
	}
	var subtitle : String? {
		didSet {
			subtitleLabel.text = subtitle?.redacted()
			subtitleLabel.isHidden = (subtitle == nil) || (subtitle?.count == 0)
		}
	}

	func configure() {
		coverImageResourceView.translatesAutoresizingMaskIntoConstraints = false
		spaceFallbackImageView.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

		contentView.addSubview(coverImageResourceView)
		contentView.addSubview(titleLabel)
		contentView.addSubview(subtitleLabel)

		let configuration = UIImage.SymbolConfiguration(hierarchicalColor: .lightGray)

		spaceFallbackImageView.image = UIImage(systemName: "rectangle.grid.2x2.fill", withConfiguration: configuration)?.withAlignmentRectInsets(UIEdgeInsets(top: -textOuterSpacing*2, left: -textOuterSpacing*2, bottom: -textOuterSpacing*2, right: -textOuterSpacing*2)).withTintColor(.darkGray)
		spaceFallbackImageView.contentMode = .scaleAspectFill

		coverImageResourceView.backgroundColor = .lightGray
		coverImageResourceView.fallbackView = spaceFallbackImageView
		coverImageResourceView.viewProviderContext = OCViewProviderContext(attributes: [.contentMode : UIView.ContentMode.scaleAspectFill.rawValue ])

		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		titleLabel.adjustsFontForContentSizeCategory = true
		titleLabel.textColor = UIColor.label
		subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
		subtitleLabel.adjustsFontForContentSizeCategory = true
		subtitleLabel.textColor = UIColor.secondaryLabel

		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		subtitleLabel.setContentHuggingPriority(.required, for: .vertical)

		coverImageResourceView.backgroundColor = .white
	}

	func configureLayout() {
		NSLayoutConstraint.activate([
			coverImageResourceView.widthAnchor.constraint(equalToConstant: 64),

			coverImageResourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			coverImageResourceView.topAnchor.constraint(equalTo: contentView.topAnchor),
			coverImageResourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

			titleLabel.leadingAnchor.constraint(equalTo: coverImageResourceView.trailingAnchor, constant: textOuterSpacing),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: textOuterSpacing),
			titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -textInterSpacing),

			subtitleLabel.leadingAnchor.constraint(equalTo: coverImageResourceView.trailingAnchor, constant: textOuterSpacing),
			subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -textOuterSpacing),

			separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
		])
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

	override func prepareForReuse() {
		super.prepareForReuse()
		coverImageResourceView.activeViewProvider = nil
		title = ""
		subtitle = ""
	}
}

class DriveListRowCell: DriveListCell {
	var labelContainer: UIView = UIView()
	var coverImageSpacing : CGFloat = 5

	override func configure() {
		super.configure()

		labelContainer.translatesAutoresizingMaskIntoConstraints = false
		labelContainer.addSubview(titleLabel)
		labelContainer.addSubview(subtitleLabel)

		contentView.addSubview(labelContainer)
		contentView.addSubview(moreButton)
	}

	private var disabledIcon: UIView?
	var isDisabled: Bool = false {
		didSet {
			if isDisabled == oldValue { return }

			// Remove disabled icon (if any)
			disabledIcon?.removeFromSuperview()
			disabledIcon = nil

			if isDisabled {
				// Create and add disabled label
				let sizeConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .large).applying(UIImage.SymbolConfiguration(paletteColors: [.lightGray]))
				disabledIcon = UIImageView(image: UIImage(systemName: "pause.circle", withConfiguration: sizeConfig))
				disabledIcon?.translatesAutoresizingMaskIntoConstraints = false
				if let disabledIcon {
					embed(centered: disabledIcon, enclosingAnchors: coverImageResourceView.defaultAnchorSet)
				}
				coverImageResourceView.alpha = 0
			} else {
				coverImageResourceView.alpha = 1
			}
		}
	}

	override func configureLayout() {
		NSLayoutConstraint.activate([
			coverImageResourceView.widthAnchor.constraint(equalToConstant: 48),
			coverImageResourceView.heightAnchor.constraint(equalToConstant: 48),

			coverImageResourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textOuterSpacing),
			coverImageResourceView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: coverImageSpacing),
			coverImageResourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -coverImageSpacing),

			labelContainer.leadingAnchor.constraint(equalTo: coverImageResourceView.trailingAnchor, constant: textOuterSpacing),
			labelContainer.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -textOuterSpacing),
			labelContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

			titleLabel.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			titleLabel.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
			titleLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor),
			titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor),

			subtitleLabel.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			subtitleLabel.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
			subtitleLabel.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor),

			moreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -textOuterSpacing),
			moreButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

			separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
		])
	}
}

extension DriveListCell {
	func setupMoreButton(with cellConfiguration: CollectionViewCellConfiguration, for driveItem: OCDataItem) {
		// More item button action
		if let clientContext = cellConfiguration.clientContext, let moreItemHandling = clientContext.moreItemHandler, let drive = driveItem as? OCDrive {
			if drive.isDisabled {
				// Disabled space => show space manage UI
				moreAction = nil
				moreMenu = UIMenu(title: "", children: [
					UIAction(title: OCLocalizedString("Enable", nil), image: OCSymbol.icon(forSymbolName: "play.circle"), handler: { [weak clientContext] _ in
						drive.restore(with: clientContext)
					}),
					UIAction(title: OCLocalizedString("Delete", nil), image: OCSymbol.icon(forSymbolName: "trash"), handler: { [weak clientContext] _ in
						drive.delete(with: clientContext)
					})
				])
			} else {
				// Enabled space = show available actions
				moreMenu = nil
				moreAction = OCAction(title: OCLocalizedString("Actions", nil), icon: nil, action: { [weak moreItemHandling] (action, options, completion) in
					clientContext.core?.cachedItem(at: drive.rootLocation, resultHandler: { error, item in
						if let item {
							OnMainThread {
								moreItemHandling?.moreOptions(for: item, at: .moreFolder, context: clientContext, sender: action)
							}
						}
						completion(error)
					})
				})
			}
		}
	}

	static func registerCellProvider() {
		let driveListCellRegistration = UICollectionView.CellRegistration<DriveListRowCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var coverImageRequest : OCResourceRequest?
			var resourceManager : OCResourceManager?
			var title : String?
			var subtitle : String?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
					subtitle = presentable.subtitle

					resourceManager = cellConfiguration.core?.vault.resourceManager

					coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)

					cell.isDisabled = (item as? OCDrive)?.isDisabled ?? false

					// More item button action
					cell.setupMoreButton(with: cellConfiguration, for: item)
				}
			})

			cell.title = title
			cell.subtitle = subtitle

			cell.coverImageResourceView.request = coverImageRequest

			if let coverImageRequest = coverImageRequest {
				resourceManager?.start(coverImageRequest)
			}

			cell.secureView(core: collectionItemRef.ocCellConfiguration?.clientContext?.core)

			cell.accessories = [ .disclosureIndicator() ]
		}

		let driveHeaderCellRegistration = UICollectionView.CellRegistration<DriveHeaderCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var coverImageRequest : OCResourceRequest?
			var resourceManager : OCResourceManager?
			var title : String?
			var subtitle : String?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title?.redacted()
					subtitle = presentable.subtitle?.redacted()

					resourceManager = cellConfiguration.core?.vault.resourceManager

					coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)
				}
			})

			cell.title = title
			cell.subtitle = subtitle

			cell.coverImageResourceView.request = coverImageRequest
			cell.isRequestingCoverImage = (coverImageRequest != nil)

			cell.collectionItemRef = collectionItemRef
			cell.collectionViewController = collectionItemRef.ocCellConfiguration?.hostViewController

			cell.secureView(core: collectionItemRef.ocCellConfiguration?.clientContext?.core)

			if let coverImageRequest = coverImageRequest {
				resourceManager?.start(coverImageRequest)
			}
		}

		let driveGridCellRegistration = UICollectionView.CellRegistration<DriveGridCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var coverImageRequest : OCResourceRequest?
			var resourceManager : OCResourceManager?
			var title : String?
			var subtitle : String?
			var isDisabled : Bool?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, driveItem, cellConfiguration in
				if let presentable = OCDataRenderer.default.renderItem(driveItem, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
					subtitle = presentable.subtitle

					resourceManager = cellConfiguration.core?.vault.resourceManager

					coverImageRequest = try? presentable.provideResourceRequest(.coverImage, withOptions: nil)

					isDisabled = (driveItem as? OCDrive)?.isDisabled ?? false

					// More item button action
					cell.setupMoreButton(with: cellConfiguration, for: driveItem)
				}
			})

			cell.title = title
			cell.subtitle = subtitle
			cell.isDisabled = isDisabled ?? false

			cell.coverImageResourceView.request = coverImageRequest
			cell.isRequestingCoverImage = (coverImageRequest != nil)

			cell.collectionItemRef = collectionItemRef
			cell.collectionViewController = collectionItemRef.ocCellConfiguration?.hostViewController

			cell.secureView(core: collectionItemRef.ocCellConfiguration?.clientContext?.core)

			if let coverImageRequest = coverImageRequest {
				resourceManager?.start(coverImageRequest)
			}
		}

		let driveSideBarCellRegistration = UICollectionView.CellRegistration<ThemeableCollectionViewListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var title : String?
			var icon: UIImage?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let drive = item as? OCDrive, let specialType = drive.specialType {
					switch specialType {
						case .personal:
							icon = OCSymbol.icon(forSymbolName: "person")

						case .shares:
							icon = OCSymbol.icon(forSymbolName: "arrowshape.turn.up.left")

						case .space:
							icon = OCSymbol.icon(forSymbolName: "square.grid.2x2")

						default:
							icon = OCSymbol.icon(forSymbolName: "square.grid.2x2")
					}
				}

				if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
					title = presentable.title
				}
			})

			var content = cell.defaultContentConfiguration()

			content.text = title?.redacted()
			content.image = icon

			cell.backgroundConfiguration = UIBackgroundConfiguration.listSidebarCell()
			cell.contentConfiguration = content
			cell.applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .initial)
			cell.accessibilityTraits = .button
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .drive, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				case .header:
					return collectionView.dequeueConfiguredReusableCell(using: driveHeaderCellRegistration, for: indexPath, item: itemRef)

				case .sideBar:
					return collectionView.dequeueConfiguredReusableCell(using: driveSideBarCellRegistration, for: indexPath, item: itemRef)

				case .gridCell, .gridCellLowDetail, .gridCellNoDetail:
					return collectionView.dequeueConfiguredReusableCell(using: driveGridCellRegistration, for: indexPath, item: itemRef)

				default:
					return collectionView.dequeueConfiguredReusableCell(using: driveListCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}
