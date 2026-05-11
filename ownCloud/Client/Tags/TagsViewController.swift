//
//  TagsViewController.swift
//  ownCloud
//
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudAppShared

private class TagTableViewCell: ThemeTableViewCell {

	static let reuseIdentifier = "TagTableViewCell"

	let nameLabel = UILabel()
	private let editButton = UIButton(type: .system)
	private let deleteButton = UIButton(type: .system)
	private let buttonStack = UIStackView()

	var onEditTapped: (() -> Void)?
	var onDeleteTapped: (() -> Void)?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupViews()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupViews() {
		let primaryTextColor = UIColor { traitCollection in
			HCColor.Content.textPrimary(traitCollection.userInterfaceStyle == .dark)
		}
		let destructiveColor = UIColor { traitCollection in
			HCColor.Interaction.destructiveSolidNormal(traitCollection.userInterfaceStyle == .dark)
		}

		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		nameLabel.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)

		editButton.translatesAutoresizingMaskIntoConstraints = false
		editButton.setImage(HCIcon.edit, for: .normal)
		editButton.tintColor = primaryTextColor
		editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

		deleteButton.translatesAutoresizingMaskIntoConstraints = false
		deleteButton.setImage(HCIcon.delete, for: .normal)
		deleteButton.tintColor = destructiveColor
		deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

		buttonStack.translatesAutoresizingMaskIntoConstraints = false
		buttonStack.axis = .horizontal
		buttonStack.spacing = 16
		buttonStack.alignment = .center
		buttonStack.addArrangedSubview(editButton)
		buttonStack.addArrangedSubview(deleteButton)

		contentView.addSubview(nameLabel)
		contentView.addSubview(buttonStack)

		NSLayoutConstraint.activate([
			nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
			nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: -8),

			buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
			buttonStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			buttonStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
			buttonStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

			editButton.widthAnchor.constraint(equalToConstant: 24),
			editButton.heightAnchor.constraint(equalToConstant: 24),
			deleteButton.widthAnchor.constraint(equalToConstant: 24),
			deleteButton.heightAnchor.constraint(equalToConstant: 24)
		])
	}

	func setManagementEnabled(_ enabled: Bool) {
		buttonStack.isHidden = !enabled
	}

	@objc private func editTapped() {
		onEditTapped?()
	}

	@objc private func deleteTapped() {
		onDeleteTapped?()
	}
}

class TagsViewController: UITableViewController, Themeable {

	private var clientContext: ClientContext
	private var tags: [OCSystemTag] = []
	private var emptyStateView: ComposedMessageView?
	private var themeRegistered = false
	private var canManageTags = true

	init(context: ClientContext) {
		self.clientContext = context
		super.init(style: .plain)
		self.title = OCLocalizedString("Tags", nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(TagTableViewCell.self, forCellReuseIdentifier: TagTableViewCell.reuseIdentifier)
		tableView.rowHeight = 50
		tableView.tableFooterView = UIView()
		setupEmptyState()

		updateAddButton()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if !themeRegistered {
			themeRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}

		fetchTags()
	}

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	// MARK: - Themeable

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection)
		tableView.reloadData()
		tableView.backgroundColor = HCColor.Structure.appBackground(collection.isDark)
		view.backgroundColor = HCColor.Structure.appBackground(collection.isDark)
	}

	// MARK: - Tags API

	private var connection: OCConnection? {
		return clientContext.core?.connection
	}

	private func fetchTags() {
		guard let connection = connection else { return }

		connection.retrieveSystemTags { [weak self] error, fetchedTags in
			OnMainThread {
				guard let self else { return }
				if let error {
					self.showError(error, title: HCL10n.TagsList.loadingError)
					return
				}
				self.tags = (fetchedTags ?? []).sorted { $0.displayName < $1.displayName }
				self.tableView.reloadData()
				self.updateEmptyStateVisibility()
			}
		}
	}

	private func setupEmptyState() {
		let emptyView = ComposedMessageView(elements: [
			.image(OCSymbol.icon(forSymbolName: "tag") ?? UIImage(), size: CGSize(width: 48, height: 48), alignment: .centered),
			.title(HCL10n.TagsList.empty, alignment: .centered)
		])
		emptyView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(emptyView)
		NSLayoutConstraint.activate([
			emptyView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
			emptyView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
		])
		emptyView.isHidden = true
		emptyStateView = emptyView
	}

	private func updateEmptyStateVisibility() {
		emptyStateView?.isHidden = !tags.isEmpty
	}

	private func updateAddButton() {
		if canManageTags {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				image: UIImage(systemName: "plus"),
				style: .plain,
				target: self,
				action: #selector(addTag)
			)
		} else {
			navigationItem.rightBarButtonItem = nil
		}
	}

	// MARK: - Actions

	@objc private func addTag() {
		presentTagEditor(tag: nil)
	}

	private func openFileList(for tag: OCSystemTag) {
		guard let connection = connection else { return }
		let context = ClientContext(with: clientContext)

		let buildFilesViewController: (ClientContext) -> ClientItemViewController = { context in
			let itemsDataSource = OCDataSourceArray(items: [])
			let sortedDataSource = SortedItemDataSource(itemDataSource: itemsDataSource)

			let filesVC = ClientItemViewController(
				context: context,
				query: nil,
				itemsDatasource: sortedDataSource,
				showRevealButtonForItems: true,
				emptyItemListIcon: OCSymbol.icon(forSymbolName: "tag"),
				emptyItemListTitleLocalized: OCLocalizedString("No files found", nil),
				emptyItemListMessageLocalized: OCLocalizedString("No files are tagged with this tag.", nil)
			)
			filesVC.useOverlayEmptyState = true
			filesVC.navigationTitle = "\"\(tag.displayName)\""
			filesVC.revoke(in: context, when: [.connectionClosed])

			let eventTarget = OCEventTarget(ephermalEventHandlerBlock: { [weak itemsDataSource] (event: OCEvent, _: Any?) in
				if event.error != nil { return }
				if let items = event.result as? [OCItem] {
					OnMainThread {
						itemsDataSource?.setVersionedItems(items)
					}
				}
			}, userInfo: nil, ephermalUserInfo: nil)

			connection.retrieveFiles(with: tag, resultTarget: eventTarget)
			sortedDataSource.sortingFollowsContext = filesVC.clientContext
			return filesVC
		}

		let openedViewController = context.pushViewControllerToNavigation(context: context, provider: { context in
			return buildFilesViewController(context)
		}, push: true, animated: true)

		if openedViewController == nil {
			let fallbackVC = buildFilesViewController(context)
			let navController = ThemeNavigationController(rootViewController: fallbackVC)
			present(navController, animated: true)
		}
	}

	private func editTag(_ tag: OCSystemTag) {
		presentTagEditor(tag: tag)
	}

	private func deleteTag(_ tag: OCSystemTag, at indexPath: IndexPath) {
		let alert = UIAlertController(
			title: HCL10n.TagsList.Delete.title,
			message: String(format: HCL10n.TagsList.Delete.description, tag.displayName),
			preferredStyle: .alert
		)

		alert.addAction(UIAlertAction(title: HCL10n.TagsList.Delete.cancel, style: .cancel))
		alert.addAction(UIAlertAction(title: HCL10n.TagsList.Delete.confirm, style: .destructive) { [weak self] _ in
			self?.performDelete(tag: tag, at: indexPath)
		})

		present(alert, animated: true)
	}

	private func performDelete(tag: OCSystemTag, at indexPath: IndexPath) {
		guard let connection = connection else { return }

		connection.delete(tag) { [weak self] error in
			OnMainThread {
				guard let self else { return }
				if let error {
					self.showError(error, title: HCL10n.TagsList.Delete.error)
					return
				}
				self.tags.remove(at: indexPath.row)
				self.tableView.deleteRows(at: [indexPath], with: .automatic)
				self.updateEmptyStateVisibility()
			}
		}
	}

	private func presentTagEditor(tag: OCSystemTag?) {
		let editVC = TagEditViewController(tag: tag) { [weak self] newName in
			guard let self, let newName else { return }
			if let existingTag = tag {
				self.performUpdate(tag: existingTag, newName: newName)
			} else {
				self.performCreate(name: newName)
			}
		}

		let nav = ThemeNavigationController(rootViewController: editVC)
		nav.modalPresentationStyle = .formSheet
		present(nav, animated: true)
	}

	private func performCreate(name: String) {
		guard let connection = connection else { return }

		connection.createSystemTag(withName: name, userVisible: true, userAssignable: true) { [weak self] error, newTag in
			OnMainThread {
				guard let self else { return }
				if let error {
					self.showTagOperationError(error, fallbackTitle: HCL10n.TagsList.Create.error)
					return
				}
				if let newTag {
					self.tags.append(newTag)
					self.tags.sort { $0.displayName < $1.displayName }
					self.tableView.reloadData()
					self.updateEmptyStateVisibility()
				}
			}
		}
	}

	private func performUpdate(tag: OCSystemTag, newName: String) {
		guard let connection = connection else { return }

		connection.update(tag, withDisplayName: newName) { [weak self] error in
			OnMainThread {
				guard let self else { return }
				if let error {
					self.showTagOperationError(error, fallbackTitle: HCL10n.TagsList.Update.error)
					return
				}
				if let idx = self.tags.firstIndex(where: { $0.identifier == tag.identifier }) {
					self.tags[idx].displayName = newName
					self.tags.sort { $0.displayName < $1.displayName }
					self.tableView.reloadData()
					self.updateEmptyStateVisibility()
				}
			}
		}
	}

	private func showTagOperationError(_ error: Error, fallbackTitle: String) {
		let nsError = error as NSError
		if nsError.isOCError(withCode: .itemAlreadyExists) {
			presentAlert(title: HCL10n.TagsList.alreadyExists, message: nil)
			return
		}
		showError(error, title: fallbackTitle)
	}

	private func showError(_ error: Error, title: String) {
		presentAlert(title: title, message: error.localizedDescription)
	}

	private func presentAlert(title: String, message: String?) {
		let alert = ThemedAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: HCL10n.TagsList.errorOk, style: .default))
		clientContext.present(alert, animated: true)
	}

	// MARK: - UITableViewDataSource / Delegate

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		openFileList(for: tags[indexPath.row])
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tags.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: TagTableViewCell.reuseIdentifier, for: indexPath) as? TagTableViewCell else {
			return UITableViewCell()
		}

		let tag = tags[indexPath.row]
		cell.nameLabel.text = tag.displayName
		cell.setManagementEnabled(canManageTags)

		cell.onEditTapped = { [weak self] in
			self?.editTag(tag)
		}

		cell.onDeleteTapped = { [weak self] in
			self?.deleteTag(tag, at: indexPath)
		}

		return cell
	}
}
