//
//  ShareViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 18.04.23.
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

open class ShareViewController: CollectionViewController, SearchViewControllerDelegate {
	public enum Mode {
		case create
		case edit
	}

	public enum ShareType {
		case share
		case link

		static func from(share: OCShare) -> ShareType {
			switch share.type {
				case .link: return .link
				default: return .share
			}
		}

		func shareType(recipient: OCIdentity) -> OCShareType {
			switch self {
				case .link:
					return .link

				default:
					if recipient.user != nil {
						return .userShare
					} else {
						return .groupShare
					}
			}
		}
	}

	public var share: OCShare?
	public var item: OCItem?
	public var location: OCLocation?
	public var name: String?
	public var type: ShareType
	public var mode: Mode

	public var recipient: OCIdentity? {
		willSet {
		}
		didSet {
			if recipient != nil {
				searchViewController?.endSearch()
				recipientsSection?.boundarySupplementaryItems = [
					.mediumTitle(OCLocalizedString("Share with", nil))
				]
			} else {
				recipientsSection?.boundarySupplementaryItems = nil
			}
			if recipientDatasource == nil {
				recipientDatasource = OCDataSourceArray(items: [])
				recipientsSectionDatasource?.addSources([recipientDatasource!])
			}

			if let recipientDatasource {
				if let recipient {
					recipientDatasource.setVersionedItems([ recipient ])
				} else {
					recipientDatasource.setVersionedItems([])
				}
			}

			updateRoles(for: recipient)
			updateState()
		}
	}
	var recipientDatasource: OCDataSourceArray?

	var recipientSearchController: OCRecipientSearchController?
	var recipientsSectionDatasource: OCDataSourceComposition?
	var recipientsSection: CollectionViewSection?

	var rolesSectionOptionGroup: OptionGroup?
	var rolesSectionDatasource: OCDataSourceArray?
	var rolesSection: CollectionViewSection?

	var linksSectionDatasource: OCDataSourceArray?
	var linksSection: CollectionViewSection?

	var nameTextField : UITextField?

	var customPermissionsSectionOptionGroup: OptionGroup?
	var customPermissionsDatasource: OCDataSourceArray?
	var customPermissionsSection: CollectionViewSection?

	var optionsSectionDatasource: OCDataSourceArray?
	var optionsSection: CollectionViewSection?

	var bottomButtonBar: BottomButtonBar?

	public typealias CompletionHandler = (_ share: OCShare?) -> Void

	var completionHandler: CompletionHandler?
	var identityFilter: RecipientSearchScope.RecipientFilter?

	public init(type: ShareType = .share, mode: Mode, share: OCShare? = nil, item: OCItem? = nil, clientContext: ClientContext, identityFilter: RecipientSearchScope.RecipientFilter? = nil, completion: @escaping CompletionHandler) {
		var sections: [CollectionViewSection] = []

		self.share = share
		self.permissions = share?.permissions
		self.expirationDate = share?.expirationDate
		self.type = (share != nil) ? ShareType.from(share: share!) : type
		self.location = item?.location ?? share?.itemLocation
		self.item = (item != nil) ? item! : ((location != nil) ? try? clientContext.core?.cachedItem(at: location!) : nil)
		self.mode = mode
		self.completionHandler = completion
		self.identityFilter = identityFilter

		// Item section
		if let item = item {
			let itemSectionContext = ClientContext(with: clientContext, modifier: { context in
				context.permissions = []
			})
			let itemSectionDatasource = OCDataSourceArray(items: [item])
			let itemSection = CollectionViewSection(identifier: "item", dataSource: itemSectionDatasource, cellStyle: .init(with: .header), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), clientContext: itemSectionContext)
			sections.append(itemSection)
		}

		// Managament section cell style
		let managementCellStyle: CollectionViewCellStyle = .init(with: .tableCell)
		managementCellStyle.options = [
			.showManagementView : true,
			.withoutDisclosure : true
		]

		let managementLineCellStyle: CollectionViewCellStyle = .init(with: .tableLine)
		managementLineCellStyle.options = managementCellStyle.options

		// Adapted context
		let shareControllerContext = ClientContext(with: clientContext)
		shareControllerContext.postInitializationModifier = { (owner, context) in
			context.originatingViewController = owner as? UIViewController
		}

		// - Recipients section
		recipientsSectionDatasource = OCDataSourceComposition(sources: [])
		recipientsSection = CollectionViewSection(identifier: "recipients", dataSource: recipientsSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)

		if let recipientsSection, self.type == .share {
			sections.append(recipientsSection)
		}

		// - Links
		var linksSectionContext = shareControllerContext
		if self.type == .link, self.mode == .edit, share != nil {
			// Prevent clicks on links during editing
			linksSectionContext = ClientContext(with: shareControllerContext, modifier: { context in
				context.permissions = []
			})
		}

		linksSectionDatasource = OCDataSourceArray(items: [])
		linksSection =  CollectionViewSection(identifier: "links", dataSource: linksSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: linksSectionContext)

		if let linksSection, self.type == .link, self.mode == .edit, let share {
			linksSectionDatasource?.setVersionedItems([share])
			sections.append(linksSection)
		}

		// - Name
		if self.type == .link {
			let textField : UITextField = ThemeCSSTextField()
			textField.translatesAutoresizingMaskIntoConstraints = false
			textField.setContentHuggingPriority(.required, for: .vertical)
			textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
			textField.placeholder = share?.token ?? OCLocalizedString("Link", nil)
			textField.text = share?.name
			textField.accessibilityLabel = OCLocalizedString("Name", nil)

			nameTextField = textField

			let spacerView = UIView()
			spacerView.translatesAutoresizingMaskIntoConstraints = false
			spacerView.embed(toFillWith: textField, insets: NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18))

			let nameSectionDatasource = OCDataSourceArray(items: [spacerView])
			let nameSection = CollectionViewSection(identifier: "name", dataSource: nameSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)
			nameSection.boundarySupplementaryItems = [
				.mediumTitle(OCLocalizedString("Name", nil))
			]

			sections.append(nameSection)
		}

		// - Roles & permissions
		rolesSectionDatasource = OCDataSourceArray()

		rolesSection = CollectionViewSection(identifier: "roles", dataSource: rolesSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)
		rolesSection?.boundarySupplementaryItems = [
			.mediumTitle(OCLocalizedString("Permissions", nil))
		]
		rolesSection?.hidden = true

		if let rolesSection {
			sections.append(rolesSection)
		}

		customPermissionsDatasource = OCDataSourceArray(items: [])
		customPermissionsSection = CollectionViewSection(identifier: "customPermissions", dataSource: customPermissionsDatasource, cellStyle: managementLineCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)

		if let customPermissionsSection {
			sections.append(customPermissionsSection)
		}

		// - Options
		optionsSectionDatasource = OCDataSourceArray(items: [
		])
		optionsSection = CollectionViewSection(identifier: "options", dataSource: optionsSectionDatasource, cellStyle: managementLineCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)
		optionsSection?.hideIfEmptyDataSource = optionsSectionDatasource
		optionsSection?.boundarySupplementaryItems = [
			.mediumTitle(OCLocalizedString("Options", nil))
		]

		if let optionsSection {
			sections.append(optionsSection)
		}

		super.init(context: shareControllerContext, sections: sections, useStackViewRoot: true, compressForKeyboard: true)

		self.cssSelector = .grouped

		linksSectionContext.originatingViewController = self

		revoke(in: clientContext, when: [ .connectionClosed, .connectionOffline ])

		// Add defaults for creation
		if self.type == .link, self.mode == .create, share == nil, expirationDate == nil {
			if clientContext.core?.connection.capabilities?.publicSharingExpireDateAddDefaultDate == true,
			   let numberOfDays = clientContext.core?.connection.capabilities?.publicSharingDefaultExpireDateDays {
				expirationDate = Date(timeIntervalSinceNow: numberOfDays.doubleValue * (24 * 60 * 60))
			}
		}
	}

	required public init?(coder: NSCoder) {
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

		// Set navigation bar title
		var navigationTitle: String?

		switch mode {
		case .create:
			navigationTitle = (type == .link) ? OCLocalizedString("Create link", nil) : OCLocalizedString("Invite", nil)

		case .edit:
			navigationTitle = OCLocalizedString("Edit", nil)
		}
		navigationItem.titleLabelText = navigationTitle

		// Add bottom button bar
		let isLinkCreation = (mode == .create) && (type == .link)
 		let title = (mode == .create) ? ((type == .link) ? OCLocalizedString("Share", nil) : OCLocalizedString("Invite", nil)) : OCLocalizedString("Save changes", nil)
		let altTitle = isLinkCreation ? OCLocalizedString("Create", nil) : nil

		bottomButtonBar = BottomButtonBar(selectButtonTitle: title, alternativeButtonTitle: altTitle, cancelButtonTitle: OCLocalizedString("Cancel", nil), hasAlternativeButton: isLinkCreation, hasCancelButton: true, selectAction: UIAction(handler: { [weak self] _ in
			self?.save(andShare: isLinkCreation)
		}), alternativeAction: isLinkCreation ? UIAction(handler: { [weak self] _ in
			self?.save()
		}) : nil, cancelAction: UIAction(handler: { [weak self] _ in
			self?.complete()
		}))
		bottomButtonBar?.showActivityIndicatorWhileModalActionRunning = mode != .edit

		let bottomButtonBarViewController = UIViewController()
		bottomButtonBarViewController.view = bottomButtonBar

		// - Add delete button for existing shares
		if mode == .edit {
			let unshare = UIBarButtonItem(title: OCLocalizedString("Unshare", nil), style: .plain, target: self, action: #selector(deleteShare))
			unshare.tintColor = .red

			self.navigationItem.rightBarButtonItem = unshare
		}

		self.addStacked(child: bottomButtonBarViewController, position: .bottom)

		// Wire up name textfield
		self.name = share?.name
		nameTextField?.addAction(UIAction(handler: { [weak self, weak nameTextField] _ in
			if let nameTextField {
				self?.name = nameTextField.text
			}
		}), for: .allEditingEvents)

		// Set up view
		if let share, let core = clientContext?.core {
			role = core.matching(for: share, from: nil)
		}

		if let share, let recipient = share.recipient {
			self.recipient = recipient
		} else {
			switch type {
				case .share:
					startSearch()

				case .link:
					updateRoles()
			}
		}

		updateState()
	}

	// MARK: - Share Role & permissions
	public var permissions: OCSharePermissionsMask? {
		didSet {
			updateState()
		}
	}

	public var role: OCShareRole? {
		didSet {
			if role?.type != .custom {
				permissions = role?.permissions
			} else if let role {
				let mandatoryPermissions = role.permissions.subtracting(role.customizablePermissions)
				permissions = permissions?.union(mandatoryPermissions) ?? role.permissions
			}

			showCustomPermissions(for: role)

			if let role {
				rolesSectionOptionGroup?.chosenValues = [role]
			} else {
				rolesSectionOptionGroup?.chosenValues = []
			}

			updateState()
			updateOptions()
		}
	}

	func updateRoles(for identity: OCIdentity? = nil) {
		var shareType: OCShareType?

		switch type {
			case .share:
				if let identity {
					shareType = (identity.type == .group) ? .groupShare : .userShare
				}

			case .link:
				shareType = .link
		}

		if let location, let clientContext, let shareType {
			if let shareRoles = clientContext.sharingRoles {
				self.shareRoles = shareRoles
			} else {
				clientContext.core?.availableShareRoles(for: shareType, location: location, completionHandler: { [weak self] error, shareRoles in
					if let shareRoles {
						OnMainThread {
							self?.shareRoles = shareRoles
						}
					}
				})
			}
		} else {
			rolesSection?.hidden = true
		}
	}

	var shareRoles: [OCShareRole]? {
		didSet {
			_updateRoles(with: shareRoles)
		}
	}

	private func _updateRoles(with shareRoles: [OCShareRole]?) {
		if let shareRoles {
			let roleOptions: [OptionItem] = shareRoles.map({ shareRole in
				OptionItem(kind: .multipleChoice, contentFrom: shareRole, state: shareRole == role)
			})

			rolesSectionOptionGroup = OptionGroup()
			rolesSectionOptionGroup?.items = roleOptions
			rolesSectionOptionGroup?.changeAction = { [weak self] (group, selectedItem) in
				self?.role = selectedItem.value as? OCShareRole
			}
			if let role {
				rolesSectionOptionGroup?.chosenValues = [ role ]
			}

			rolesSectionDatasource?.setVersionedItems(roleOptions)
			rolesSection?.hidden = false

			if role == nil, let share, let core = clientContext?.core {
				role = core.matching(for: share, from: shareRoles)
			}

		} else {
			rolesSection?.hidden = true
		}
	}

	func showCustomPermissions(for role: OCShareRole?) {
		if let role, role.type == .custom {
			let selectedPermissions = permissions ?? []
			let customizablePermissions = role.customizablePermissions

			var permissionOptions: [OptionItem] = []

			func addPermissionOption(title: String, iconName: String, permission: OCSharePermissionsMask) {
				if customizablePermissions.contains(permission) || (self.permissions?.contains(permission) == true) {
					let image = OCSymbol.icon(forSymbolName: iconName)
					permissionOptions.append(OptionItem(kind: .toggle, content: .init(with: .text(title), icon: ((image != nil) ? .icon(image: image!) : nil)), value: permission, enabled: customizablePermissions.contains(permission), state: selectedPermissions.contains(permission)))
				}
			}

			if type == .link {
				addPermissionOption(title: OCLocalizedString("Download / View", nil), iconName: "eye", permission: .read)
			} else {
				addPermissionOption(title: OCLocalizedString("Read", nil), iconName: "eye", permission: .read)
			}
			addPermissionOption(title: OCLocalizedString("Edit", nil), iconName: "character.cursor.ibeam", permission: .update)
			addPermissionOption(title: OCLocalizedString("Upload", nil), iconName: "arrow.up.circle.fill", permission: .create)
			addPermissionOption(title: OCLocalizedString("Delete", nil), iconName: "trash", permission: .delete)
			addPermissionOption(title: OCLocalizedString("Share", nil), iconName: "person.badge.plus", permission: .share)

			customPermissionsSectionOptionGroup = OptionGroup()
			customPermissionsSectionOptionGroup?.items = permissionOptions
			customPermissionsSectionOptionGroup?.changeAction = { [weak self] (group, selectedItem) in
				if let permission = selectedItem.value as? OCSharePermissionsMask {
					if selectedItem.state {
						self?.permissions?.formUnion(permission)
					} else {
						self?.permissions?.remove(permission)
					}
				}
			}

			customPermissionsDatasource?.setVersionedItems(permissionOptions)

			customPermissionsSection?.hidden = false
		} else {
			customPermissionsSection?.hidden = true
		}
	}

	// MARK: - Search + SearchViewControllerDelegate
	var searchViewController: SearchViewController?
	var searchActive: Bool = false

	var searchResultsContent: SearchViewController.Content? {
		didSet {
			if let content = searchResultsContent {
				let contentSource = content.source

				if searchResultsDataSource != contentSource {
					searchResultsDataSource = contentSource
				}
			} else {
				searchResultsDataSource = nil
			}
		}
	}

	var searchResultsDataSource: OCDataSource? {
		willSet {
			if let oldDataSource = searchResultsDataSource, oldDataSource != newValue {
				recipientsSectionDatasource?.removeSources([ oldDataSource ])
			}
		}

		didSet {
			if let newDataSource = searchResultsDataSource {
				recipientsSectionDatasource?.addSources([ newDataSource ])
			}
		}
	}

	@objc open func startSearch() {
		if searchViewController == nil {
			if let clientContext, let item, let cellStyle = recipientsSection?.cellStyle {
				let placeholderCellStyle: CollectionViewCellStyle = .init(with: .fillSpace)

				// No results
				let noResultContent = SearchViewController.Content(type: .noResults, source: OCDataSourceArray(), style: placeholderCellStyle)
				let noResultsView = ComposedMessageView.infoBox(image: OCSymbol.icon(forSymbolName: "magnifyingglass"), title: OCLocalizedString("No matches", nil), subtitle: OCLocalizedString("No user or group matches your search.", nil), withRoundedBackgroundView: false)

				(noResultContent.source as? OCDataSourceArray)?.setVersionedItems([
					noResultsView
				])

				// Suggestion view
				let suggestionsSource = OCDataSourceArray(items: [ ComposedMessageView.infoBox(image: nil, subtitle: OCLocalizedString("Enter the user or group you want to invite.", nil), withRoundedBackgroundView: false) ])
				let suggestionsContent = SearchViewController.Content(type: .suggestion, source: suggestionsSource, style: placeholderCellStyle)

				// Create and install SearchViewController
				searchViewController = SearchViewController(with: clientContext, scopes: [
					.recipientSearch(with: clientContext, cellStyle: cellStyle, item: item, localizedName: "Share with", filter: identityFilter)
				], suggestionContent: suggestionsContent, noResultContent: noResultContent, delegate: self)

				if let searchViewController = searchViewController {
					self.addStacked(child: searchViewController, position: .top)
				}
			}
		}
	}

	public func searchBegan(for viewController: SearchViewController) {
		searchActive = true
	}

	public func search(for viewController: SearchViewController, content: SearchViewController.Content?) {
		searchResultsContent = content
	}

	public func searchEnded(for viewController: SearchViewController) {
		searchActive = false

		if let searchViewController = searchViewController {
			self.removeStacked(child: searchViewController)
		}
		searchResultsContent = nil
		searchViewController = nil

		if type == .share, recipient == nil {
			self.dismiss(animated: true, completion: nil)
		}
	}

	public override func allowSelection(of record: OCDataItemRecord, at indexPath: IndexPath, clientContext: ClientContext) -> Bool {
		if record.item is OCIdentity {
			return searchActive
		}

		return super.allowSelection(of: record, at: indexPath, clientContext: clientContext)
	}

	public override func handleSelection(of record: OCDataItemRecord, at indexPath: IndexPath, clientContext: ClientContext) -> Bool {
		if let identity = record.item as? OCIdentity, searchActive {
			recipient = identity
			collectionView.deselectItem(at: indexPath, animated: true)

			return true
		}

		return super.handleSelection(of: record, at: indexPath, clientContext: clientContext)
	}

	// MARK: - State
	func updateState() {
		var createIsEnabled: Bool

		switch type {
			case .link:
				createIsEnabled = (location != nil) && (role != nil) && (permissions != nil)

			case .share:
				createIsEnabled = (location != nil) && (recipient != nil) && (role != nil) && (permissions != nil)
		}

		// Enforce password requirements
		if hasPasswordOption && passwordRequired && !hasPassword {
			createIsEnabled = false
		}

		// Enforce expiration date requirements
		if hasExpirationOption && expirationDateRequired && (expirationDate == nil) {
			createIsEnabled = false
		}

		bottomButtonBar?.selectButton.isEnabled = createIsEnabled
		bottomButtonBar?.alternativeButton.isEnabled = createIsEnabled
	}

	// MARK: - Options
	var passwordOption: OptionItem?
	var password: String? {
		didSet {
			updateState()
		}
	}
	var removePassword: Bool = false {
		didSet {
			updateState()
		}
	}
	var passwordPolicy: OCPasswordPolicy {
		return clientContext?.core?.connection.capabilities?.passwordPolicy ?? OCPasswordPolicy.default
	}

	var expiryOption: OptionItem?
	var expirationDatePicker: UIDatePicker?
	var expirationDate: Date? {
		didSet {
			updateState()
		}
	}

	var hasPasswordOption: Bool {
		return type == .link
	}
	var passwordRequired: Bool {
		if type == .link, let capabilities = clientContext?.core?.connection.capabilities {
			if capabilities.publicSharingPasswordEnforced == true {
				return true
			}
			if permissions?.contains(.read) == true &&
			   permissions?.contains(.delete) == true && (
				permissions?.contains(.create) == true ||
				permissions?.contains(.update) == true) {
				// Read/Write/Delete
				if mode == .edit {
					return capabilities.publicSharingPasswordBlockRemovalForReadWriteDelete == true
				}
				return capabilities.publicSharingPasswordEnforcedForReadWriteDelete == true
			}
			if permissions?.contains(.read) == true && (
				permissions?.contains(.create) == true ||
				permissions?.contains(.update) == true) {
				// Read/Write
				if mode == .edit {
					return capabilities.publicSharingPasswordBlockRemovalForReadWrite == true
				}
				return capabilities.publicSharingPasswordEnforcedForReadWrite == true
			}
			if permissions?.contains(.create) == true {
				// Upload only
				if mode == .edit {
					return capabilities.publicSharingPasswordBlockRemovalForUploadOnly == true
				}
				return capabilities.publicSharingPasswordEnforcedForUploadOnly == true
			}
			if permissions?.contains(.read) == true {
				// Read only
				if mode == .edit {
					return capabilities.publicSharingPasswordBlockRemovalForReadOnly == true
				}
				return capabilities.publicSharingPasswordEnforcedForReadOnly == true
			}
		}
		return false
	}
	var hasExpirationOption: Bool {
		return (type == .link) || (clientContext?.core?.connection.useDriveAPI == true)
	}
	var expirationDateRequired: Bool {
		return type == .link ? (clientContext?.core?.connection.capabilities?.publicSharingExpireDateEnforceDateAndDaysDeterminesLastAllowedDate == true) : false
	}

	func updateOptions() {
		var options: [OCDataItem & OCDataItemVersioning] = []

		// Password
		if hasPasswordOption {
			var accessories: [UICellAccessory] = []
			var details: [SegmentViewItem] = []
			var customActions: [UIAccessibilityCustomAction] = []

			let makeButton: (_ title: String, _ action: @escaping UIActionHandler) -> UIButton = { (title, action) in
				var buttonConfig = UIButton.Configuration.plain()
				buttonConfig.title = title
				buttonConfig.contentInsets = .zero

				let uiAction = UIAction(handler: action)

				let button = ThemeCSSButton()
				button.configuration = buttonConfig
				button.addAction(uiAction, for: .primaryActionTriggered)

				customActions.append(UIAccessibilityCustomAction(name: title, actionHandler: { _ in
					action(uiAction)
					return true
				}))

				return button
			}

			if ((share?.protectedByPassword == true) && !removePassword) || (password != nil) {
				if password != nil {
					let copyButton = makeButton(OCLocalizedString("Copy", nil), { [weak self] action in
						if let self, let password = self.password {
							UIPasteboard.general.string = password
							_ = NotificationHUDViewController(on: self, title: OCLocalizedString("Password", nil), subtitle: OCLocalizedString("The password was copied to the clipboard", nil), completion: nil)
						}
					})

					details.append(contentsOf: [
						SegmentViewItem(view: copyButton),
						SegmentViewItem(title: "|", style: .label)
					])
				}

				details.append(.detailText("******"))

				let removePassword = { [weak self] in
					self?.password = nil
					self?.removePassword = true
					self?.updateOptions()
				}

				accessories = [
					.button(image: OCSymbol.icon(forSymbolName: "xmark.circle.fill"), accessibilityLabel: OCLocalizedString("Remove password", nil), action: UIAction(handler: { _ in
						removePassword()
					}))
				]

				customActions.append(UIAccessibilityCustomAction(name: OCLocalizedString("Remove password", nil), actionHandler: { _ in
					removePassword()
					return true
				}))
			} else {
				if passwordRequired {
					details.append(.detailText("⚠️"))
				}

				let generateButton = makeButton(OCLocalizedString("Generate", nil), { [weak self] action in
					self?.generatePassword()
				})

				let addButton = makeButton(OCLocalizedString("Set", nil), { [weak self] action in
					self?.requestPassword()
				})

				details.append(contentsOf: [SegmentViewItem(view: generateButton), SegmentViewItem(title: "|", style: .label), SegmentViewItem(view: addButton)])
			}

			let content = UniversalItemListCell.Content(with: .text(OCLocalizedString("Password", nil)), iconSymbolName: "key.fill", accessories: accessories)
			content.details = details
			content.accessibilityCustomActions = customActions

			if passwordOption == nil {
				passwordOption = OptionItem(kind: .single, content: content, state: false, selectionAction: { [weak self] optionItem in
					self?.requestPassword()
				})
			} else {
				passwordOption?.content = content
			}

			if let passwordOption {
				options.append(passwordOption)
			}
		}

		// Expiration
		if hasExpirationOption {
			var accessories: [UICellAccessory] = []
			var details: [SegmentViewItem] = []
			var customActions: [UIAccessibilityCustomAction] = []

			let addExpirationDate = { [weak self] in
				self?.expirationDate = .now.addingTimeInterval(24 * 3600 * 7)
				self?.updateOptions()
			}

			if let expirationDate {
				if expirationDatePicker == nil {
					let datePicker = UIDatePicker()
					datePicker.preferredDatePickerStyle = .compact
					datePicker.datePickerMode = .date
					datePicker.minimumDate = .now
					if clientContext?.core?.connection.capabilities?.publicSharingExpireDateEnforceDateAndDaysDeterminesLastAllowedDate == true,
					   let numberOfDays = clientContext?.core?.connection.capabilities?.publicSharingDefaultExpireDateDays {
						datePicker.maximumDate = Date(timeIntervalSinceNow: numberOfDays.doubleValue * (24 * 60 * 60))
					}
					datePicker.date = expirationDate
					datePicker.addAction(UIAction(handler: { [weak self, weak datePicker] action in
						self?.expirationDate = datePicker?.date
						self?.updateOptions()
					}), for: .valueChanged)

					expirationDatePicker = datePicker
				} else {
					expirationDatePicker?.date = expirationDate
				}

				if let expirationDatePicker {
					details.append(SegmentViewItem(view: expirationDatePicker))
				}

				let removeExpirationDate = { [weak self] in
					self?.expirationDate = nil
					self?.updateOptions()
				}

				accessories = [
					.button(image: OCSymbol.icon(forSymbolName: "xmark.circle.fill"), accessibilityLabel: OCLocalizedString("Remove expiration date", nil), action: UIAction(handler: { _ in
						removeExpirationDate()
					}))
				]

				customActions.append(UIAccessibilityCustomAction(name: OCLocalizedString("Extend by one week", nil), actionHandler: { [weak self] _ in
					if let expirationDate = self?.expirationDate {
						self?.expirationDate = expirationDate.addingTimeInterval(7 * 24 * 60 * 60)
						self?.updateOptions()
					}
					return true
				}))

				if expirationDate.timeIntervalSinceNow > (7 * 24 * 60 * 60) {
					customActions.append(UIAccessibilityCustomAction(name: OCLocalizedString("Shorten by one week", nil), actionHandler: { [weak self] _ in
						if let expirationDate = self?.expirationDate {
							self?.expirationDate = expirationDate.addingTimeInterval(-7 * 24 * 60 * 60)
							self?.updateOptions()
						}
						return true
					}))
				}

				customActions.append(UIAccessibilityCustomAction(name: OCLocalizedString("Remove expiration date", nil), actionHandler: { _ in
					removeExpirationDate()
					return true
				}))
			} else {
				var buttonConfig = UIButton.Configuration.plain()
				buttonConfig.title = OCLocalizedString("Add", nil)
				buttonConfig.contentInsets = .zero

				let button = ThemeCSSButton()
				button.configuration = buttonConfig
				button.addAction(UIAction(handler: { _ in
					addExpirationDate()
				}), for: .primaryActionTriggered)

				if expirationDateRequired {
					details.append(.detailText("⚠️"))
				}

				details.append(SegmentViewItem(view: button))

				customActions.append(UIAccessibilityCustomAction(name: OCLocalizedString("Add", nil), actionHandler: { _ in
					addExpirationDate()
					return true
				}))
			}

			let content = UniversalItemListCell.Content(with: .text(OCLocalizedString("Expiration date", nil)), iconSymbolName: "calendar", accessories: accessories)
			content.details = details
			content.accessibilityCustomActions = customActions
			content.accessibilityLabel = OCLocalizedString("Expiration date", nil) + " " + ((expirationDate != nil) ? OCItem.accessibilityDateFormatter.string(for: expirationDate!) ?? "" : "")

			if expiryOption == nil {
				expiryOption = OptionItem(kind: .single, content: content, state: false)
			} else {
				expiryOption?.content = content
			}

			expiryOption?.selectAction = {  [weak self] optionItem in
				if self?.expirationDate == nil {
					addExpirationDate()
				} else if let picker = self?.expirationDatePicker {
					picker.sendActions(for: .primaryActionTriggered)
				}
			}

			if let expiryOption {
				options.append(expiryOption)
			}
		}

		optionsSectionDatasource?.setVersionedItems(options)
	}

	private var hasPassword: Bool {
		return ((share?.protectedByPassword == true) && !removePassword) || (password != nil)
	}
	func requestPassword() {
		let passwordViewController = PasswordComposerViewController(password: password ?? "", policy: passwordPolicy, saveButtonTitle: OCLocalizedString("Set", nil), resultHandler: { [weak self] password, cancelled in
			if !cancelled, let password {
				self?.password = password
				self?.removePassword = false
				self?.updateOptions()
			}
		})
		let navigationViewController = passwordViewController.viewControllerForPresentation()

		if mode == .edit, hasPassword {
			passwordViewController.navigationItem.title = OCLocalizedString("Change password", nil)
		}

		self.clientContext?.present(navigationViewController, animated: true)
	}
	func generatePassword() {
		var generatedPassword: String?
		do {
			try generatedPassword = passwordPolicy.generatePassword(withMinLength: nil, maxLength: nil)
		} catch let error as NSError {
			Log.error("Error generating password: \(error)")
		}
		if let generatedPassword {
			self.password = generatedPassword
			self.removePassword = false
			self.updateOptions()
		}
	}

	// MARK: - Save (edit + create)
	func save(andShare: Bool = false) {
		let presentingViewController = UIDevice.current.isIpad ? self : self.presentingViewController

		switch mode {
			case .create:
				var newShare: OCShare?
				var sharePermission: OCSharePermission?

				if clientContext?.core?.useDrives == true, let role {
					sharePermission = OCSharePermission(role: role)
				} else if let permissions {
					sharePermission = OCSharePermission(permissionsMask: permissions)
				}

				switch type {
					case .share:
						if let recipient, let sharePermission, let location {
							newShare = OCShare(recipient: recipient, location: location, permissions: [sharePermission], expiration: nil)
						}

					case .link:
						if let location, let sharePermission {
							newShare = OCShare(publicLinkTo: location, linkName: name, permissions: [sharePermission], password: nil, expiration: nil)
						}
				}

				if let password {
					newShare?.password = password
					newShare?.protectedByPassword = true
				}

				if let expirationDate {
					newShare?.expirationDate = expirationDate
				}

				if let item, newShare?.itemFileID == nil {
					newShare?.itemFileID = item.fileID
				}

				guard let core = clientContext?.core, let newShare else {
					self.showError(NSError(ocError: .internal))
					return
				}

				bottomButtonBar?.modalActionRunning = true

				core.createShare(newShare, completionHandler: { error, share in
					OnMainThread {
						self.bottomButtonBar?.modalActionRunning = false
					}

					if let error {
						self.showError(error)
					} else {
						if let url = share?.url, andShare {
							let existingCompletionHandler = UIDevice.current.isIpad ? { (share) in
								// On iPad, first show Share Sheet, then close ShareViewController
								self.complete(with: share)
							} : self.completionHandler // On iPhone, first close ShareViewController, then show Share Sheet

							let handleResultAndShowShareSheet: CompletionHandler = { (share) in
								let absoluteURLString = url.absoluteString
								var shareMessage: String?

								if let password = self.password {
									// Message consists of Link + Password
									if let displayName = self.location?.displayName(in: nil) {
										shareMessage = OCLocalizedFormat("{{itemName}} ({{link}}) | password: {{password}}", [
											"itemName" : displayName,
											"link" : absoluteURLString,
											"password" : password
										])
									} else {
										shareMessage = OCLocalizedFormat("{{link}} | password: {{password}}", [
											"link" : absoluteURLString,
											"password" : password
										])
									}
								} else {
									// Message consists of Link only
									shareMessage = absoluteURLString
								}

								if let shareMessage, let presentingViewController {
									// Show Share Sheet
									OnMainThread {
										let shareViewController = UIActivityViewController(activityItems: [shareMessage], applicationActivities:nil)

										if UIDevice.current.isIpad {
											shareViewController.popoverPresentationController?.sourceView = self.bottomButtonBar?.selectButton ?? self.view
										}

										shareViewController.completionWithItemsHandler = { (_, _, _, _) in
											// Completed
											existingCompletionHandler?(share)
										}

										presentingViewController.present(shareViewController, animated: true, completion: nil)
									}
								} else {
									// Completed
									existingCompletionHandler?(share)
								}
							}

							if UIDevice.current.isIpad {
								// On iPad, first show Share Sheet, then close ShareViewController
								handleResultAndShowShareSheet(share)
								return // Avoid calling self.complete(with:), called via existingCompletionHandler
							} else {
								// On iPhone, first close ShareViewController, then show Share Sheet
								self.completionHandler = handleResultAndShowShareSheet
							}
						}

						self.complete(with: share)
					}
				})

			case .edit:
				switch type {
					case .share, .link:
						if let permissions {
							if let core = clientContext?.core, let share {
								bottomButtonBar?.modalActionRunning = true

								core.update(share, afterPerformingChanges: { [weak self] share in
									if share.firstRoleID != nil, let role = self?.role {
										share.sharePermissions = [ OCSharePermission(role: role) ]
									} else {
										share.permissions = permissions
									}

									if let removePassword = self?.removePassword, removePassword {
										share.password = nil
										share.protectedByPassword = false
									} else if let password = self?.password {
										share.password = password
										share.protectedByPassword = true
									}

									if self?.type == .link {
										share.name = self?.name
									}

									share.expirationDate = self?.expirationDate
								}, completionHandler: { error, share in
									OnMainThread {
										self.bottomButtonBar?.modalActionRunning = false
									}

									if let error {
										self.showError(error)
									} else {
										self.complete(with: share)
									}
								})
							} else {
								self.showError(NSError(ocError: .internal))
							}
						}
				}
		}
	}

	@objc func deleteShare() {
		guard let core = clientContext?.core, let share else {
			self.showError(NSError(ocError: .internal))
			return
		}

		core.delete(share, completionHandler: { error in
			if let error {
				self.showError(error)
			} else {
				self.complete()
			}
		})
	}

	func showError(_ error: Error) {
		OnMainThread {
			let alertController = ThemedAlertController(with: OCLocalizedString("An error occurred", nil), message: error.localizedDescription, okLabel: OCLocalizedString("OK", nil), action: nil)
			self.present(alertController, animated: true)
		}
	}

	// MARK: - Completion
	func complete(with share: OCShare? = nil) {
		func callCompletionHandler() {
			if let completionHandler {
				self.completionHandler = nil
				completionHandler(share)
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
