//
//  SpaceManagementViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 10.12.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public class SpaceManagementViewController: CollectionViewController {
	public enum Mode {
		case create
		case edit
		case details
	}

	var drive: OCDrive?
	var mode: Mode

	var name: String? {
		didSet {
			updateState()
		}
	}
	var nameTextField: UITextField

	var subtitle: String? {
		didSet {
			updateState()
		}
	}
	var subtitleTextField: UITextField

	var quotaValid: Bool = true
	var quota: Int64? {
		didSet {
			updateState()
		}
	}
	var quotaTextField: UITextField
	var quotaFormatter: ByteCountFormatter

	var shareQuery: OCShareQuery?

	var bottomButtonBar: BottomButtonBar?

	public typealias CompletionHandler = (_ error: Error?, _ drive: OCDrive?) -> Void
	var completionHandler: CompletionHandler?

	static func addTextFieldSection(withID sectionID: String, title: String, placeholder: String, text: String?, accessibilityLabel: String?, clientContext: ClientContext) -> (UITextField, CollectionViewSection) {
		let cellStyle: CollectionViewCellStyle = .init(with: .tableCell)
		let textField = ThemeCSSTextField.formField(withPlaceholder: placeholder, text: text, accessibilityLabel: accessibilityLabel)
		let sectionDatasource = OCDataSourceArray(items: [textField.withPadding()])
		let section = CollectionViewSection(identifier: sectionID, dataSource: sectionDatasource, cellStyle: cellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: clientContext)
		section.boundarySupplementaryItems = [
			.mediumTitle(title)
		]

		return (textField, section)
	}

	public init(clientContext: ClientContext, drive: OCDrive? = nil, mode: Mode = .create, completionHandler: CompletionHandler?) {
		var sections: [CollectionViewSection] = []
		var section: CollectionViewSection

		defer {
			// Use defer to also trigger the didSet
			self.drive = drive
		}
		self.mode = mode
		self.completionHandler = completionHandler

		let spaceControllerContext = ClientContext(with: clientContext)
		spaceControllerContext.postInitializationModifier = { (owner, context) in
			context.originatingViewController = owner as? UIViewController
		}

		// Naming section
		(nameTextField, section) = SpaceManagementViewController.addTextFieldSection(withID: "name", title: OCLocalizedString("Name", nil), placeholder: OCLocalizedString("Name", nil), text: drive?.name, accessibilityLabel: OCLocalizedString("Name", nil), clientContext: spaceControllerContext)
		sections.append(section)

		// Subtitle (descripton) section
		(subtitleTextField, section) = SpaceManagementViewController.addTextFieldSection(withID: "subtitle", title: OCLocalizedString("Subtitle", nil), placeholder: OCLocalizedString("Subtitle", nil), text: drive?.desc, accessibilityLabel: OCLocalizedString("Subtitle", nil), clientContext: spaceControllerContext)
		sections.append(section)

		// Quota section
		(quotaTextField, section) = SpaceManagementViewController.addTextFieldSection(withID: "quota", title: OCLocalizedString("Quota", nil), placeholder: OCLocalizedString("Available space", nil), text: drive?.desc, accessibilityLabel: OCLocalizedString("Available space", nil), clientContext: spaceControllerContext)
		// sections.append(section)
		quotaFormatter = ByteCountFormatter()

		// Owner section
		let cellStyle: CollectionViewCellStyle = .init(with: .tableCell)

		let managementCellStyle: CollectionViewCellStyle = .init(with: .tableCell)
		managementCellStyle.options = [
			.showManagementView : true
		]

		ownerSectionDatasource = OCDataSourceArray(items: [])
		ownerSection = CollectionViewSection(identifier: "owner", dataSource: ownerSectionDatasource, cellStyle: cellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: spaceControllerContext)
		ownerSection?.boundarySupplementaryItems = [
			.mediumTitle(OCLocalizedString("Owner",nil))
		]
		ownerSection?.hidden = true
		sections.append(ownerSection!)

		// Permissions section
		permissionSectionDatasource = OCDataSourceArray(items: [])
		permissionSection = CollectionViewSection(identifier: "permissions", dataSource: permissionSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: spaceControllerContext)
		permissionSection?.boundarySupplementaryItems = [
			.mediumTitle(OCLocalizedString("Permissions",nil))
		]
		permissionSection?.hidden = (mode == .create)
		sections.append(permissionSection!)

		super.init(context: spaceControllerContext, sections: sections, useStackViewRoot: true)

		cssSelector = .grouped
	}

	@MainActor required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if let shareQuery {
			clientContext?.core?.stop(shareQuery)
		}
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		// Disable dragging of items, so keyboard control does
		// not include "Drag Item" in the accessibility actions
		// invoked with Tab + Z
		dragInteractionEnabled = false

		// Add extra content inset on top
		var extraContentInset = collectionView.contentInset
		extraContentInset.top += 10
		collectionView.contentInset = extraContentInset

		// Set titles
		var navigationTitle: String?
		var selectButtonTitle: String
		var hasCancelButton = true

		switch mode {
		case .create:
			navigationTitle = OCLocalizedString("Create space", nil)
			selectButtonTitle = OCLocalizedString("Create", nil)

		case .edit:
			navigationTitle = OCLocalizedString("Edit space", nil)
			selectButtonTitle = OCLocalizedString("Save", nil)

		case .details:
			navigationTitle = drive?.name ?? OCLocalizedString("Details", nil)
			selectButtonTitle = OCLocalizedString("Close", nil)
			hasCancelButton = false
		}
		navigationItem.titleLabelText = navigationTitle

		// Add bottom button bar
		bottomButtonBar = BottomButtonBar(selectButtonTitle: selectButtonTitle, alternativeButtonTitle: nil, cancelButtonTitle: OCLocalizedString("Cancel", nil), hasCancelButton: hasCancelButton, selectAction: UIAction(handler: { [weak self] _ in
			self?.save()
		}), cancelAction: UIAction(handler: { [weak self] _ in
			self?.complete()
		}))
		bottomButtonBar?.showActivityIndicatorWhileModalActionRunning = mode != .edit

		let bottomButtonBarViewController = UIViewController()
		bottomButtonBarViewController.view = bottomButtonBar
		self.addStacked(child: bottomButtonBarViewController, position: .bottom)

		// Wire up name textfield
		self.name = drive?.name
		nameTextField.addAction(UIAction(handler: { [weak self, weak nameTextField] _ in
			if let nameTextField {
				self?.name = nameTextField.text
			}
		}), for: .allEditingEvents)

		// Wire up subtitle textfield
		self.subtitle = drive?.desc
		subtitleTextField.addAction(UIAction(handler: { [weak self, weak subtitleTextField] _ in
			if let subtitleTextField {
				self?.subtitle = subtitleTextField.text
			}
		}), for: .allEditingEvents)

		// Wire up quota textfield
		self.quota = drive?.quota?.total?.int64Value
		quotaTextField.addAction(UIAction(handler: { [weak self, weak quotaTextField] _ in
			if let quotaTextField, let self {
				var bytes: AnyObject?
				var errorDesc: NSString?
				self.quotaValid = self.quotaFormatter.getObjectValue(&bytes, for: quotaTextField.text ?? "", errorDescription: &errorDesc)
				if self.quotaValid {
					self.quota = bytes as? Int64
				}
			}
		}), for: .allEditingEvents)

		if let drive, let core = clientContext?.core, let driveRootItem = try? core.cachedItem(at: drive.rootLocation) {
			shareQuery = OCShareQuery(scope: .item, item: driveRootItem)
			shareQuery?.refreshInterval = 5
			shareQuery?.changesAvailableNotificationHandler = { [weak self] query in
				OnMainThread {
					self?.permissionSection?.clientContext?.sharingRoles = query.allowedRoles // Needs to use the section's clientContext as self.context can be (is) a copy of the spaceControllerContext used for creating that section and setting its .sharingRoles would therefore not be visible to the section's cells
					self?.permissions = (query.queryResults as NSArray).sortedArray(comparator: { share1, share2 in
						let weight1 = ((share1 as? OCShare)?.sharePermissions?.first?.role?.weight ?? 0)
						let weight2 = ((share2 as? OCShare)?.sharePermissions?.first?.role?.weight ?? 0)

						if weight1.intValue > weight2.intValue {
							return .orderedAscending
						}
						if weight1.intValue < weight2.intValue {
							return .orderedDescending
						}

						return .orderedSame
					}) as? [OCShare]
				}
			}

			if let shareQuery {
				core.start(shareQuery)
			}
		}

		// Set up view
		updateState()
	}

	var permissions: [OCShare]? {
		didSet {
			if let permissions {
				permissionSectionDatasource?.setVersionedItems(permissions)
			} else {
				permissionSectionDatasource?.setVersionedItems([])
			}
		}
	}
	var permissionSection: CollectionViewSection?
	var permissionSectionDatasource: OCDataSourceArray?

	var owner: OCIdentity? {
		didSet {
			if let owner {
				ownerSectionDatasource?.setVersionedItems([ owner ])
				ownerSection?.hidden = false
			} else {
				ownerSectionDatasource?.setVersionedItems([])
				ownerSection?.hidden = true
			}
		}
	}
	var ownerSection: CollectionViewSection?
	var ownerSectionDatasource: OCDataSourceArray?

	func updateState() {
		var createOrSaveIsEnabled: Bool

		createOrSaveIsEnabled = self.name?.count ?? 0 > 0

		bottomButtonBar?.selectButton.isEnabled = createOrSaveIsEnabled
	}

	func save() {
		guard let name, let clientContext, let core = clientContext.core else {
			complete()
			return
		}

		switch mode {
			case .create:
				core.connection.createDrive(withName: name, description: subtitle, quota: nil) { [weak self] error, drive in
					self?.complete(with: drive, error: error)
				}

			case .edit:
				guard let drive else {
					complete()
					return
				}

				var changes: [OCDriveProperty : Any] = [
					.name: name
				]

				if let subtitle {
					changes[.description] = subtitle
				}

				core.connection.updateDrive(drive, properties: changes) { [weak self] error, drive in
					self?.complete(with: drive, error: error)
				}

				complete()

			case .details:
				// Do nothing, just close
				complete()
		}
	}

	// MARK: - Completion
	func complete(with drive: OCDrive? = nil, error: Error? = nil) {
		func callCompletionHandler() {
			if let completionHandler {
				self.completionHandler = nil
				completionHandler(error, drive)
			}
		}

		OnMainThread(inline: true) {
			if error == nil {
				self.clientContext?.core?.fetchUpdates()
			}

			if self.presentingViewController != nil {
				self.dismiss(animated: true, completion: {
					callCompletionHandler()
				})
			} else {
				callCompletionHandler()
			}
		}
	}
}
