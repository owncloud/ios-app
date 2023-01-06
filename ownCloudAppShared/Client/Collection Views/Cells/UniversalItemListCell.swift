//
//  UniversalItemListCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.01.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp
import ownCloudSDK

public protocol UniversalItemListCellContentProvider {
	func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) //!< Provides content for cell, completion must be called immediately or - if delayed - via main thread. Helper objects must be stored in .contentProviderUserInfo immediately upon function invocation. If new content is set, .contentProviderUserInfo may be overwritten, so this should only be used to keep a reference to a helper object, but not to retrieve the helper object again. Updates to content can be provided by calling completion repeatedly. However, updates should stop if completion returns false, which indicates that the cell is now presenting other content.
}

open class UniversalItemListCell: ThemeableCollectionViewListCell {
	public class Content {
		public struct Fields: OptionSet {
			public let rawValue: Int
			public init(rawValue: Int) {
				self.rawValue = rawValue
			}

			static public let title = Fields(rawValue: 1)
			static public let icon = Fields(rawValue: 2)
			static public let details = Fields(rawValue: 4)
			static public let progress = Fields(rawValue: 8)
			static public let accessories = Fields(rawValue: 16)
			static public let disabled = Fields(rawValue: 32)
		}

		init(with inDataItem: OCDataItem?) {
			dataItem = inDataItem
		}

		public enum Title {
			case text(_ string: String)
			case file(name: String)
			case folder(name: String)
		}

		public enum Icon {
			case file
			case folder
			case mime(type: String)
			case resource(request: OCResourceRequest)
		}

		var title: Title?
		var icon: Icon?
		var iconDisabled: Bool = false

		var details: [SegmentViewItem]?

		var progress: Progress?
		var accessories: [UICellAccessory]?

		var disabled: Bool = false

		var dataItem: OCDataItem?

		var onlyFields: Fields?
	}

	public typealias ContentUpdater = (UniversalItemListCell.Content) -> Bool

	open var titleLabel: UILabel = UILabel()
	open var detailSegmentView: SegmentView = SegmentView(with: [], truncationMode: .truncateTail)

	private let iconSize : CGSize = CGSize(width: 40, height: 40)
	public let thumbnailSize : CGSize = CGSize(width: 60, height: 60) // when changing size, also update .iconView.fallbackSize
	open var iconView: ResourceViewHost = ResourceViewHost(fallbackSize: CGSize(width: 60, height: 60)) // when changing size, also update .thumbnailSize

	open weak var clientContext: ClientContext?

	// MARK: - Init
	override init(frame: CGRect) {
		super.init(frame: frame)

		prepareViews()
		updateLayoutConstraints()

		PointerEffect.install(on: self.contentView, effectStyle: .hover)
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Layout
	var cellConstraints: [NSLayoutConstraint]?

	open func prepareViews() {
		detailSegmentView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		iconView.translatesAutoresizingMaskIntoConstraints = false

		contentView.addSubview(titleLabel)
		contentView.addSubview(detailSegmentView)
		contentView.addSubview(iconView)
	}

	open func updateLayoutConstraints() {
		if let cellConstraints {
			NSLayoutConstraint.deactivate(cellConstraints)
			self.cellConstraints = nil
		}

		let horizontalMargin : CGFloat = 15
		let verticalLabelMargin : CGFloat = 10
		let verticalIconMargin : CGFloat = 10
//		let horizontalSmallMargin : CGFloat = 10
		let spacing : CGFloat = 15
//		let smallSpacing : CGFloat = 2
		let iconViewWidth : CGFloat = 40
//		let detailIconViewHeight : CGFloat = 15
//		let accessoryButtonWidth : CGFloat = 35
		let verticalLabelMarginFromCenter : CGFloat = 1

		let constraints: [NSLayoutConstraint] = [
			iconView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: horizontalMargin),
			iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -spacing),
			iconView.widthAnchor.constraint(equalToConstant: iconViewWidth),
			iconView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalIconMargin),
			iconView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalIconMargin),

			titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
			detailSegmentView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
			detailSegmentView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: verticalLabelMargin),
			titleLabel.bottomAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -verticalLabelMarginFromCenter),
			detailSegmentView.topAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: verticalLabelMarginFromCenter),
			detailSegmentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -verticalLabelMargin),

			separatorLayoutGuide.leadingAnchor.constraint(equalTo: iconView.leadingAnchor)
		]

		if constraints.count > 0 {
			cellConstraints = constraints
			NSLayoutConstraint.activate(constraints)
		}
	}

	// MARK: - Content
	var title: NSAttributedString? {
		didSet {
			titleLabel.attributedText = title
		}
	}
	var detailSegments: [SegmentViewItem]? {
		didSet {
			detailSegmentView.items = detailSegments ?? []
		}
	}

	open func set(title: String?, isFileName: Bool = false) {
		self.title = attributedTitle(for: title, isFileName: isFileName)
	}

	func attributedTitle(for title: String?, isFileName: Bool) -> NSAttributedString {
		guard let title = title as? NSString else {
			return NSAttributedString(string: "")
		}

		let pathExtension = title.pathExtension

		if isFileName, pathExtension.count > 0 {
			let baseName = title.deletingPathExtension

			return NSMutableAttributedString()
				.appendBold(baseName)
				.appendNormal(".")
				.appendNormal(pathExtension)
		} else {
			return NSMutableAttributedString()
				.appendBold(title as String)
		}
	}

	var content: Content? {
		willSet {
			let onlyFields = content?.onlyFields

			// Icon
			if onlyFields == nil || onlyFields?.contains(.icon) == true, let content {
				// Cancel any already active request
				if let icon = content.icon {
					switch icon {
						case .resource(request: let iconRequest):
							clientContext?.core?.vault.resourceManager?.stop(iconRequest)
							content.icon = nil

						default: break
					}
				}
			}
		}
		didSet {
			let onlyFields = content?.onlyFields

			// Icon
			if onlyFields == nil || onlyFields?.contains(.icon) == true {
				var iconRequest: OCResourceRequest?
				var iconViewProvider: OCViewProvider?

				if let icon = content?.icon {
					switch icon {
						case .file:
							iconViewProvider = ResourceItemIcon.file

						case .folder:
							iconViewProvider = ResourceItemIcon.folder

						case .mime(type: let type):
							iconViewProvider = ResourceItemIcon.iconFor(mimeType: type)

						case .resource(request: let request):
							iconRequest = request
					}
				}

				iconView.activeViewProvider = iconViewProvider
				iconView.request = iconRequest

				if let iconRequest {
					// Start new resource request
					clientContext?.core?.vault.resourceManager?.start(iconRequest)
				}
			}

			// Title
			if onlyFields == nil || onlyFields?.contains(.title) == true {
				if let title = content?.title {
					switch title {
						case .text(let text):
							set(title: text)

						case .file(name: let name):
							set(title: name, isFileName: true)

						case .folder(name: let name):
							set(title: name)
					}
				} else {
					set(title: nil)
				}
			}

			// Details
			if onlyFields == nil || onlyFields?.contains(.details) == true {
				if let details = content?.details {
					detailSegments = details
				} else {
					detailSegments = nil
				}
			}

			// Disabled
			if onlyFields == nil || onlyFields?.contains(.disabled) == true {
				// - Content
				if let disabled = content?.disabled, disabled {
					contentView.alpha = 0.5
				} else {
					contentView.alpha = 1.0
				}

				// - Icon
				if let disabled = content?.iconDisabled, disabled {
					iconView.alpha = 0.5
				} else {
					iconView.alpha = 1.0
				}
			}

			// Accessories
			if onlyFields == nil || onlyFields?.contains(.accessories) == true {
				if let accessories = content?.accessories {
					self.accessories = accessories
				} else {
					self.accessories = []
				}
			}

			// Progress
			if onlyFields == nil || onlyFields?.contains(.progress) == true {
				progressView?.progress = content?.progress
			}
		}
	}

	// MARK: - Content provider
	private var _contentSeed: UInt = 0
	public var contentProviderUserInfo: AnyObject? //!< Convenience property for use by ItemListCellContentProvider, to easily establish a strong reference to a helper object. Can be released or overwritten when the content changes or the cell is released.
	func fill(from contentProvider: UniversalItemListCellContentProvider, context: ClientContext? = nil, configuration: CollectionViewCellConfiguration? = nil) {
		_contentSeed += 1
		let fillSeed = _contentSeed

		clientContext = context

		contentProviderUserInfo = nil

		contentProvider.provideContent(for: self, context: context ?? configuration?.clientContext ?? clientContext, configuration: configuration) { [weak self] (content) in
			if fillSeed == self?._contentSeed {
				self?.content = content
				return true // Content presented
			}
			return false // Cell is presenting different content
		}
	}

	// MARK: - Accessories
	// - More ...
	open var moreButton: UIButton?
	open lazy var moreButtonAccessory: UICellAccessory = {
		let button = UIButton()

		button.setImage(UIImage(named: "more-dots"), for: .normal)
		button.contentMode = .center
		button.isPointerInteractionEnabled = true
		button.accessibilityLabel = "More".localized
		button.addTarget(self, action: #selector(moreButtonTapped), for: .primaryActionTriggered)

		button.widthAnchor.constraint(equalToConstant: 24).isActive = true

		moreButton = button

		return .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .whenNotEditing)))
	}()
	@objc open func moreButtonTapped() {
		guard let item = content?.dataItem, let clientContext = clientContext else {
			return
		}

		if let moreItemHandling = clientContext.moreItemHandler {
			moreItemHandling.moreOptions(for: item, at: .moreItem, context: clientContext, sender: self)
		}
	}

	// - Reveal >
	open var revealButton: UIButton?
	open lazy var revealButtonAccessory: UICellAccessory = {
		let button = UIButton()

		button.setImage(OCSymbol.icon(forSymbolName: "arrow.right.circle.fill"), for: .normal)
		button.contentMode = .center
		button.isPointerInteractionEnabled = true
		button.accessibilityLabel = "Reveal".localized
		button.addTarget(self, action: #selector(revealButtonTapped), for: .primaryActionTriggered)

		button.widthAnchor.constraint(equalToConstant: 24).isActive = true

		revealButton = button

		return .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .whenNotEditing)))
	}()

	@objc open func revealButtonTapped() {
		guard let item = content?.dataItem, let clientContext = clientContext else {
			return
		}

		clientContext.revealItemHandler?.reveal(item: item, context: clientContext, sender: self)
	}

	// - Inline message
	open var messageButton: UIButton?
	open lazy var messageButtonAccessory: UICellAccessory = {
		let button = UIButton()
		button.contentMode = .center
		button.isPointerInteractionEnabled = true
		button.accessibilityLabel = "Show message".localized
		button.setTitle("⚠️", for: .normal)
		button.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)

		messageButton = button

		return .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .whenNotEditing)))
	}()

	@objc open func messageButtonTapped() {
		guard let item = content?.dataItem as? OCItem, let clientContext = clientContext else {
			return
		}

		clientContext.inlineMessageCenter?.showInlineMessage(for: item)
	}

	// - Progress View
	open var progressView: ProgressView?
	open lazy var progressAccessory: UICellAccessory = {
		let progressView = ProgressView()
		progressView.contentMode = .center

		progressView.progress = Progress(totalUnitCount: 100)

		self.progressView = progressView

		return .customView(configuration: UICellAccessory.CustomViewConfiguration(customView: progressView, placement: .trailing(displayed: .whenNotEditing)))
	}()

	// MARK: - Prepare for reuse
	open override func prepareForReuse() {
		super.prepareForReuse()

		detailSegments = nil
		title = nil

		iconView.request = nil
		iconView.activeViewProvider = nil
	}

	// MARK: - Themeing
	open var revealHighlight : Bool = false {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}

	open override func updateConfiguration(using state: UICellConfigurationState) {
		let collection = Theme.shared.activeCollection
		var backgroundConfig = backgroundConfiguration?.updated(for: state)

		if state.isHighlighted || state.isSelected || (state.cellDropState == .targeted) || revealHighlight {
			backgroundConfig?.backgroundColor = collection.tableRowHighlightColors.backgroundColor?.withAlphaComponent(0.5)
		} else {
			backgroundConfig?.backgroundColor = collection.tableBackgroundColor
		}

		backgroundConfiguration = backgroundConfig
	}

	open override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
		titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: state)

		moreButton?.tintColor = collection.tableRowColors.secondaryLabelColor
		revealButton?.tintColor = collection.tableRowColors.secondaryLabelColor
		messageButton?.tintColor = collection.tableRowColors.secondaryLabelColor

		setNeedsUpdateConfiguration()
	}
}

// MARK: - Additional CollectionViewCellStyle.StyleOptions
public extension CollectionViewCellStyle.StyleOptionKey {
	static let showRevealButton = CollectionViewCellStyle.StyleOptionKey(rawValue: "showRevealButton")
	static let showMoreButton = CollectionViewCellStyle.StyleOptionKey(rawValue: "showMoreButton")
}

public extension CollectionViewCellStyle {
	var showRevealButton : Bool {
		get {
			return options[.showRevealButton] as? Bool ?? false
		}

		set {
			options[.showRevealButton] = newValue
		}
	}

	var showMoreButton : Bool {
		get {
			return options[.showMoreButton] as? Bool ?? true
		}

		set {
			options[.showMoreButton] = newValue
		}
	}
}

