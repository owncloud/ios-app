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
					.mediumTitle("Share with".localized)
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

	public init(type: ShareType = .share, mode: Mode, share: OCShare? = nil, item: OCItem? = nil, clientContext: ClientContext, completion: @escaping CompletionHandler) {
		var sections: [CollectionViewSection] = []

		self.share = share
		self.permissions = share?.permissions
		self.expirationDate = share?.expirationDate
		self.type = (share != nil) ? ShareType.from(share: share!) : type
		self.location = item?.location ?? share?.itemLocation
		self.item = (item != nil) ? item! : ((location != nil) ? try? clientContext.core?.cachedItem(at: location!) : nil)
		self.mode = mode
		self.completionHandler = completion

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
			textField.placeholder = share?.token ?? "Link".localized
			textField.text = share?.name
			textField.accessibilityLabel = "Name".localized

			nameTextField = textField

			let spacerView = UIView()
			spacerView.translatesAutoresizingMaskIntoConstraints = false
			spacerView.embed(toFillWith: textField, insets: NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18))

			let nameSectionDatasource = OCDataSourceArray(items: [spacerView])
			let nameSection = CollectionViewSection(identifier: "name", dataSource: nameSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)
			nameSection.boundarySupplementaryItems = [
				.mediumTitle("Name".localized)
			]

			sections.append(nameSection)
		}

		// - Roles & permissions
		rolesSectionDatasource = OCDataSourceArray()

		rolesSection = CollectionViewSection(identifier: "roles", dataSource: rolesSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: shareControllerContext)
		rolesSection?.boundarySupplementaryItems = [
			.mediumTitle("Permissions".localized)
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
			.mediumTitle("Options".localized)
		]

		if let optionsSection {
			sections.append(optionsSection)
		}

		super.init(context: shareControllerContext, sections: sections, useStackViewRoot: true, compressForKeyboard: true)

		self.cssSelector = .grouped

		linksSectionContext.originatingViewController = self

		revoke(in: clientContext, when: [ .connectionClosed, .connectionOffline ])
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		// Add extra content inset on top
		var extraContentInset = collectionView.contentInset
		extraContentInset.top += 10
		collectionView.contentInset = extraContentInset

		// Set navigation bar title
		var navigationTitle: String?

		switch mode {
		case .create:
			navigationTitle = (type == .link) ? "Create link".localized : "Invite".localized

		case .edit:
			navigationTitle = "Edit".localized
		}
		navigationItem.titleLabelText = navigationTitle

		// Add bottom button bar
		let title = (mode == .create) ? ((type == .link) ? "Create link".localized : "Invite".localized) : "Save changes".localized

		bottomButtonBar = BottomButtonBar(selectButtonTitle: title, cancelButtonTitle: "Cancel".localized, hasCancelButton: true, selectAction: UIAction(handler: { [weak self] _ in
			self?.save()
		}), cancelAction: UIAction(handler: { [weak self] _ in
			self?.complete()
		}))
		bottomButtonBar?.showActivityIndicatorWhileModalActionRunning = mode != .edit

		let bottomButtonBarViewController = UIViewController()
		bottomButtonBarViewController.view = bottomButtonBar

		// - Add delete button for existing shares
		if mode == .edit {
			let unshare = UIBarButtonItem(title: "Unshare".localized, style: .plain, target: self, action: #selector(deleteShare))
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
			role = core.matchingShareRole(for: share)
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
			if let shareRoles = clientContext.core?.availableShareRoles(for: shareType, location: location) {
				let roleOptions: [OptionItem] = shareRoles.map({ shareRole in
					OptionItem(kind: .multipleChoice, contentFrom: shareRole, state: (shareRole == role))
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
				addPermissionOption(title: "Download / View".localized, iconName: "eye", permission: .read)
			} else {
				addPermissionOption(title: "Read".localized, iconName: "eye", permission: .read)
			}
			addPermissionOption(title: "Edit".localized, iconName: "character.cursor.ibeam", permission: .update)
			addPermissionOption(title: "Upload".localized, iconName: "arrow.up.circle.fill", permission: .create)
			addPermissionOption(title: "Delete".localized, iconName: "trash", permission: .delete)
			addPermissionOption(title: "Share".localized, iconName: "person.badge.plus", permission: .share)

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
				let noResultsView = ComposedMessageView.infoBox(image: OCSymbol.icon(forSymbolName: "magnifyingglass"), title: "No matches".localized, subtitle: "No user or group matches your search.".localized, withRoundedBackgroundView: false)

				(noResultContent.source as? OCDataSourceArray)?.setVersionedItems([
					noResultsView
				])

				// Suggestion view
				let suggestionsSource = OCDataSourceArray(items: [ ComposedMessageView.infoBox(image: nil, subtitle: "Enter the user or group you want to invite.".localized, withRoundedBackgroundView: false) ])
				let suggestionsContent = SearchViewController.Content(type: .suggestion, source: suggestionsSource, style: placeholderCellStyle)

				// Create and install SearchViewController
				searchViewController = SearchViewController(with: clientContext, scopes: [
					.recipientSearch(with: clientContext, cellStyle: cellStyle, item: item, localizedName: "Share with")
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
		if record.item as? OCIdentity != nil {
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
		switch type {
			case .link:
				bottomButtonBar?.selectButton.isEnabled = (location != nil) && (role != nil) && (permissions != nil)

			case .share:
				bottomButtonBar?.selectButton.isEnabled = (location != nil) && (recipient != nil) && (role != nil) && (permissions != nil)
		}
	}

	// MARK: - Options
	var passwordOption: OptionItem?
	var password: String?
	var removePassword: Bool = false

	var expiryOption: OptionItem?
	var expirationDatePicker: UIDatePicker?
	var expirationDate: Date?

	func updateOptions() {
		let hasPasswordOption = type == .link
		let hasExpirationOption = true

		var options: [OCDataItem & OCDataItemVersioning] = []

		// Password
		if hasPasswordOption {
			var accessories: [UICellAccessory] = []
			var details: [SegmentViewItem] = []

			if ((share?.protectedByPassword == true) && !removePassword) || (password != nil) {
				details.append(.detailText("******"))

				accessories = [
					.button(image: OCSymbol.icon(forSymbolName: "xmark.circle.fill"), accessibilityLabel: "Remove password".localized, action: UIAction(handler: { [weak self] action in
						self?.password = nil
						self?.removePassword = true
						self?.updateOptions()
					}))
				]
			} else {
				var buttonConfig = UIButton.Configuration.plain()
				buttonConfig.title = "Add".localized
				buttonConfig.contentInsets = .zero

				let button = ThemeCSSButton()
				button.configuration = buttonConfig
				button.addAction(UIAction(handler: { [weak self] action in
					self?.requestPassword()
				}), for: .primaryActionTriggered)

				details.append(SegmentViewItem(view: button))
			}

			let content = UniversalItemListCell.Content(with: .text("Password".localized), iconSymbolName: "key.fill", accessories: accessories)
			content.details = details

			if passwordOption == nil {
				passwordOption = OptionItem(kind: .single, content: content, state: false, selectionAction: { [weak self] optionItem in
					if self?.hasPassword == true {
						self?.requestPassword()
					}
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

			if let expirationDate {
				if expirationDatePicker == nil {
					let datePicker = UIDatePicker()
					datePicker.preferredDatePickerStyle = .compact
					datePicker.datePickerMode = .date
					datePicker.minimumDate = .now
					datePicker.date = expirationDate
					datePicker.addAction(UIAction(handler: { [weak self, weak datePicker] action in
						self?.expirationDate = datePicker?.date
						self?.updateOptions()
					}), for: .valueChanged)

					expirationDatePicker = datePicker
				}

				if let expirationDatePicker {
					details.append(SegmentViewItem(view: expirationDatePicker))
				}

				accessories = [
					.button(image: OCSymbol.icon(forSymbolName: "xmark.circle.fill"), accessibilityLabel: "Remove expiration date".localized, action: UIAction(handler: { [weak self] action in
						self?.expirationDate = nil
						self?.updateOptions()
					}))
				]
			} else {
				var buttonConfig = UIButton.Configuration.plain()
				buttonConfig.title = "Add".localized
				buttonConfig.contentInsets = .zero

				let button = ThemeCSSButton()
				button.configuration = buttonConfig
				button.addAction(UIAction(handler: { [weak self] action in
					self?.expirationDate = .now.addingTimeInterval(24 * 3600 * 7)
					self?.updateOptions()
				}), for: .primaryActionTriggered)

				details.append(SegmentViewItem(view: button))
			}

			let content = UniversalItemListCell.Content(with: .text("Expiration date".localized), iconSymbolName: "calendar", accessories: accessories)
			content.details = details

			if expiryOption == nil {
				expiryOption = OptionItem(kind: .single, content: content, state: false)
			} else {
				expiryOption?.content = content
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
		let passwordPrompt = UIAlertController(title: "Enter password".localized, message: nil, preferredStyle: .alert)

		passwordPrompt.addTextField(configurationHandler: { textField in
			textField.placeholder = "Password".localized
			textField.isSecureTextEntry = true
		})

		passwordPrompt.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
		passwordPrompt.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { [weak self, weak passwordPrompt] action in
			self?.password = passwordPrompt?.textFields?.first?.text
			self?.updateOptions()
		}))

		self.clientContext?.present(passwordPrompt, animated: true)
	}

	// MARK: - Save (edit + create)
	func save() {
		switch mode {
			case .create:
				var newShare: OCShare?

				switch type {
					case .share:
						if let recipient, let permissions, let location {
							newShare = OCShare(recipient: recipient, location: location, permissions: permissions, expiration: nil)
						}

					case .link:
						if let location, let permissions {
							newShare = OCShare(publicLinkTo: location, linkName: name, permissions: permissions, password: nil, expiration: nil)
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
									share.permissions = permissions

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
			let alertController = ThemedAlertController(with: "An error occurred".localized, message: error.localizedDescription, okLabel: "OK".localized, action: nil)
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
