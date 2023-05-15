//
//  OptionItem.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.23.
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
import ownCloudSDK

open class OptionItem: NSObject, OCDataItem, OCDataItemVersioning, UniversalItemListCellContentProvider, DataItemSelectionInteraction {
	public enum Kind: Equatable {
		case multipleChoice
		case multipleGroupChoice(groupID: String)
		case toggle
		case single
	}

	public typealias Action = (OptionItem) -> Void

	weak open var group: OptionGroup?

	open var kind: Kind
	open var content: UniversalItemListCell.Content? {
		didSet {
			_performedInitialContentUpdate = false
			updateContent()
		}
	}
	open var enabled: Bool {
		didSet {
			updateContent()
		}
	}
	open var state: Bool {
		didSet {
			updateContent()
		}
	}

	open var value: Any?

	open var selectAction: Action?

	public init(kind: Kind, content: UniversalItemListCell.Content?, value: Any? = nil, enabled: Bool = true, state: Bool = false, selectionAction: Action? = nil) {
		self.kind = kind
		self.content = content
		self.value = value
		self.enabled = enabled
		self.state = state
		self.selectAction = selectionAction
	}

	convenience public init(kind: Kind, contentFrom contentProvider: UniversalItemListCellContentProvider, value: Any? = nil, enabled: Bool = true, state: Bool = false, selectionAction: Action? = nil) {
		self.init(kind: kind, content: nil, enabled: enabled, state: state, selectionAction: selectionAction)
		self.contentProvider = contentProvider
		self.value = value ?? contentProvider
	}

	// MARK: - Content provider
	private var contentProvider: UniversalItemListCellContentProvider?
	private var contentUpdater: UniversalItemListCell.ContentUpdater?

	private var _performedInitialContentUpdate = false
	private func updateContent() {
		if let content, let contentUpdater {
			let updatedContent = UniversalItemListCell.Content(with: content)

			if _performedInitialContentUpdate {
				updatedContent.onlyFields = [.accessories, .disabled]
			}
			_performedInitialContentUpdate = true

			if state {
				var combinedAccessories = updatedContent.accessories ?? []

				combinedAccessories.append(.checkmark())

				updatedContent.accessories = combinedAccessories
			}

			updatedContent.disabled = !enabled

			let continueUpdating = contentUpdater(updatedContent)

			if continueUpdating == false {
				self.contentUpdater = nil
			}
		}
	}

	open func provideContent(for cell: UniversalItemListCell, context: ClientContext?, configuration: CollectionViewCellConfiguration?, updateContent: @escaping UniversalItemListCell.ContentUpdater) {
		_performedInitialContentUpdate = false
		contentUpdater = updateContent

		if content == nil, let contentProvider {
			// Retrieve content from contentProvider
			contentProvider.provideContent(for: cell, context: context, configuration: configuration, updateContent: { [weak self] content in
				self?.content = content // Store content from contentProvider

				// Modify content and send it via the contentUpdater
				self?.updateContent()

				return false // Tell contentProvider to not keep updating the content
			})
		} else {
			// Bring content up-to-date and send it via the contentUpdater
			self.updateContent()
		}
	}

	// MARK: - Selection interaction
	open func allowSelection(in viewController: UIViewController?, section: CollectionViewSection?, with context: ClientContext?) -> Bool {
		return enabled
	}

	open func handleSelection(in viewController: UIViewController?, with context: ClientContext?, completion: ((Bool) -> Void)?) -> Bool {
		if kind != .single {
			if kind == .toggle {
				state = !state
			} else {
				state = true
			}

			group?.update(with: self)
		}

		selectAction?(self)

		completion?(true)
		return true
	}

	// MARK: - OCDataItem & OCDataItemVersioning
	open var dataItemType: OCDataItemType {
		return .optionItem
	}

	open var dataItemReference: OCDataItemReference {
		return NSString(format: "<OptionItem:%p>", self)
	}

	open var dataItemVersion: OCDataItemVersion {
		return NSString(format: "<OptionItem:%p>", self)
		// return "\(enabled)\(state)" as NSString
	}
}

extension OptionItem {
	static func registerUniversalCellProvider() {
		let cellRegistration = UICollectionView.CellRegistration<UniversalItemListCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let optionItem = OCDataRenderer.default.renderItem(item, asType: .optionItem, error: nil, withOptions: nil) as? OptionItem {
					cell.fill(from: optionItem, context: cellConfiguration.clientContext, configuration: cellConfiguration)
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .optionItem, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))
	}
}

public extension OCDataItemType {
	static let optionItem = OCDataItemType(rawValue: "optionItem")
}
