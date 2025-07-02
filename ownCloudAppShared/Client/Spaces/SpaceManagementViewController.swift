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
	var rootItem: OCItem?
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

	var quotaEnabled: Bool = false {
		didSet {
			quotaTextField.isHidden = !quotaEnabled
			quotaOnOffSwitch?.isOn = quotaEnabled
		}
	}
	var quotaBytes: UInt64? {
		return quotaEnabled ? ((quotaTextField.byteCount > 0) ? quotaTextField.byteCount : nil)  : nil
	}
	var quotaTextField: ByteCountEditView
	var quotaOnOffSwitch: UISwitch?

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

	static func addQuotaSection(withID sectionID: String, title: String, switchTitle: String?, byteCount: UInt64?, accessibilityLabel: String?, clientContext: ClientContext) -> (ByteCountEditView, UISwitch?, CollectionViewSection) {
		let cellStyle: CollectionViewCellStyle = .init(with: .tableCell)
		let byteCountEditView = ByteCountEditView(withByteCount: byteCount)
		var onOffSwitch: UISwitch?
		let sectionDatasource: OCDataSourceArray

		if let switchTitle {
			let quotaSwitch = UISwitch()
			quotaSwitch.translatesAutoresizingMaskIntoConstraints = false
			onOffSwitch = quotaSwitch

			let quotaSwitchLabel = ThemeCSSLabel(withSelectors: [ .title ])
			quotaSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
			quotaSwitchLabel.setContentHuggingPriority(.required, for: .horizontal)
			quotaSwitchLabel.text = switchTitle

			let containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(quotaSwitch)
			containerView.addSubview(quotaSwitchLabel)
			containerView.addSubview(byteCountEditView)

			NSLayoutConstraint.activate([
				quotaSwitch.leftAnchor.constraint(equalTo: containerView.leftAnchor),
				quotaSwitchLabel.leftAnchor.constraint(equalTo: quotaSwitch.rightAnchor, constant: 10),
				byteCountEditView.leftAnchor.constraint(equalTo: quotaSwitchLabel.rightAnchor, constant: 10),
				byteCountEditView.rightAnchor.constraint(equalTo: containerView.rightAnchor),

				quotaSwitch.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
				quotaSwitchLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
				byteCountEditView.topAnchor.constraint(equalTo: containerView.topAnchor),
				byteCountEditView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
			])

			sectionDatasource = OCDataSourceArray(items: [containerView.withPadding()])
		} else {
			sectionDatasource = OCDataSourceArray(items: [byteCountEditView.withPadding()])
		}
		let section = CollectionViewSection(identifier: sectionID, dataSource: sectionDatasource, cellStyle: cellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: clientContext)
		section.boundarySupplementaryItems = [
			.mediumTitle(title)
		]

		return (byteCountEditView, onOffSwitch, section)
	}

	public init(clientContext: ClientContext, rootItem: OCItem? = nil, drive: OCDrive? = nil, mode: Mode = .create, completionHandler: CompletionHandler?) {
		var sections: [CollectionViewSection] = []
		var section: CollectionViewSection

		defer {
			// Use defer to also trigger the didSet
			self.drive = drive
			self.rootItem = rootItem
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
		(quotaTextField, quotaOnOffSwitch, section) = SpaceManagementViewController.addQuotaSection(withID: "quota", title: OCLocalizedString("Quota", nil), switchTitle: OCLocalizedString("Limit space", nil), byteCount: drive?.quota?.total?.uint64Value, accessibilityLabel: OCLocalizedString("Available space", nil), clientContext: spaceControllerContext)

		sections.append(section)

		// Actions section
		var actionsDataSource: OCDataSourceArray?
		var actionSection: CollectionViewSection?

		if mode != .create {
			let cellStyle: CollectionViewCellStyle = .init(with: .tableCell)
			actionsDataSource = OCDataSourceArray(items: [])
			actionSection = CollectionViewSection(identifier: "actions", dataSource: actionsDataSource, cellStyle: cellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: clientContext)
			if let actionSection {
				actionSection.boundarySupplementaryItems = [
					.mediumTitle(OCLocalizedString("Actions",nil))
				]
				actionSection.hidden = true
				sections.append(actionSection)
			}
		}

		super.init(context: spaceControllerContext, sections: sections, useStackViewRoot: true, compressForKeyboard: true)

		if let actionsDataSource, let core = spaceControllerContext.core, let rootItem {
			let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .spaceAction)
			let actionContext = ActionContext(viewController: self, clientContext: spaceControllerContext, core: core, items: [rootItem], location: actionsLocation, sender: nil)
			let actions = Action.sortedApplicableActions(for: actionContext)
			var ocActions: [OCAction] = []

			for action in actions {
				ocActions.append(action.provideOCAction())
			}

			if ocActions.count > 0 {
				actionsDataSource.setVersionedItems(ocActions)
				actionSection?.hidden = false
			}
		}

		cssSelector = .grouped
	}

	@MainActor required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
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
		let cancelButtonTitle: String? = OCLocalizedString("Cancel", nil)
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
		bottomButtonBar = BottomButtonBar(selectButtonTitle: selectButtonTitle, alternativeButtonTitle: nil, cancelButtonTitle: cancelButtonTitle, hasCancelButton: hasCancelButton, selectAction: UIAction(handler: { [weak self] _ in
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

		// Wire up quota
		quotaOnOffSwitch?.addAction(UIAction(handler: { [weak self] action in
			if let onOffSwitch = action.sender as? UISwitch {
 				let quotaEnabled = onOffSwitch.isOn

				if quotaEnabled && self?.quotaBytes == nil {
					// Quota was enabled, but quotaBytes itself is 0 => propose a 1 GB quota
					self?.quotaTextField.set(byteCount: ByteCountUnit.gigaBytes.byteCount)
					self?.quotaTextField.textField.becomeFirstResponder()
				}

				self?.quotaEnabled = quotaEnabled

			}
		}), for: .primaryActionTriggered)

		if let quota = drive?.quota {
			quotaEnabled = (quota.total?.uint64Value ?? 0) > 0
		} else {
			quotaEnabled = false
		}

		// Disable user input in detail view
		if mode == .details {
			nameTextField.isEnabled = false
			subtitleTextField.isEnabled = false
			quotaOnOffSwitch?.isEnabled = false
			quotaTextField.isUserInteractionEnabled = false
		}

		// Set up view
		updateState()
	}

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

		let quotaTotalBytes: UInt64? = quotaBytes

		if let quotaTotalBytes, quotaTotalBytes > ByteCountUnit.petaBytes.byteCount {
			OnMainThread {
				let alertController = ThemedAlertController(
					with: OCLocalizedString("Quota too high", nil),
					message: OCLocalizedString("Please enter a quota equal or less than 1 PB.", nil),
					okLabel: OCLocalizedString("OK", nil),
					preferredStyle: .alert,
					action: nil)

				self.clientContext?.present(alertController, animated: true)
			}
			return
		}

		// Disable select button to prevent triggering creation multiple times (fixes KOKO-1383)
		bottomButtonBar?.selectButton.isEnabled = false

		switch mode {
			case .create:
				core.createDrive(withName: name, description: subtitle, quota: NSNumber(value: quotaTotalBytes ?? 0), template: .default) { [weak self] error, drive in
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

				if let quotaTotalBytes {
					changes[.quotaTotal] = quotaTotalBytes
				} else {
					changes[.quotaTotal] = 0 // Setting the quota.total to 0 disables the quota
				}

				core.updateDrive(drive, properties: changes) { [weak self] error, drive in
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
