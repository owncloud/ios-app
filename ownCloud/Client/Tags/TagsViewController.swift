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
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		nameLabel.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)

		editButton.translatesAutoresizingMaskIntoConstraints = false
		editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
		editButton.accessibilityLabel = OCLocalizedString("Edit", nil)
		editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

		deleteButton.translatesAutoresizingMaskIntoConstraints = false
		deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
		deleteButton.tintColor = .systemRed
		deleteButton.accessibilityLabel = OCLocalizedString("Delete", nil)
		deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

		buttonStack.translatesAutoresizingMaskIntoConstraints = false
		buttonStack.axis = .horizontal
		buttonStack.spacing = 8
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
			buttonStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
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
					self.showError(error, title: OCLocalizedString("Error loading tags", nil))
					return
				}
				self.tags = (fetchedTags ?? []).sorted { $0.displayName < $1.displayName }
				self.tableView.reloadData()
			}
		}
	}

	// MARK: - Permission handling

	private func isPermissionsError(_ error: Error) -> Bool {
		let msg = error.localizedDescription.lowercased()
		return msg.contains("not sufficient permissions") || msg.contains("permission") || (error as NSError).code == 403
	}

	private func handlePermissionsError() {
		canManageTags = false
		updateAddButton()
		tableView.reloadData()

		let alert = UIAlertController(
			title: OCLocalizedString("Insufficient Permissions", nil),
			message: OCLocalizedString("Managing tags requires administrator privileges on the server.", nil),
			preferredStyle: .alert
		)
		alert.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default))
		present(alert, animated: true)
	}

	private func updateAddButton() {
		if canManageTags {
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				image: UIImage(systemName: "plus"),
				style: .plain,
				target: self,
				action: #selector(addTag)
			)
			navigationItem.rightBarButtonItem?.accessibilityLabel = OCLocalizedString("Add Tag", nil)
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
		filesVC.navigationTitle = tag.displayName
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

		navigationController?.pushViewController(filesVC, animated: true)
	}

	private func editTag(_ tag: OCSystemTag) {
		presentTagEditor(tag: tag)
	}

	private func deleteTag(_ tag: OCSystemTag, at indexPath: IndexPath) {
		let alert = UIAlertController(
			title: OCLocalizedString("Delete Tag", nil),
			message: String(format: OCLocalizedString("Are you sure you want to delete the tag \"%@\"?", nil), tag.displayName),
			preferredStyle: .alert
		)

		alert.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel))
		alert.addAction(UIAlertAction(title: OCLocalizedString("Delete", nil), style: .destructive) { [weak self] _ in
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
					if self.isPermissionsError(error) {
						self.handlePermissionsError()
					} else {
						self.showError(error, title: OCLocalizedString("Error deleting tag", nil))
					}
					return
				}
				self.tags.remove(at: indexPath.row)
				self.tableView.deleteRows(at: [indexPath], with: .automatic)
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
					if self.isPermissionsError(error) {
						self.handlePermissionsError()
					} else {
						self.showError(error, title: OCLocalizedString("Error creating tag", nil))
					}
					return
				}
				if let newTag {
					self.tags.append(newTag)
					self.tags.sort { $0.displayName < $1.displayName }
					self.tableView.reloadData()
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
					if self.isPermissionsError(error) {
						self.handlePermissionsError()
					} else {
						self.showError(error, title: OCLocalizedString("Error updating tag", nil))
					}
					return
				}
				if let idx = self.tags.firstIndex(where: { $0.identifier == tag.identifier }) {
					self.tags[idx].displayName = newName
					self.tags.sort { $0.displayName < $1.displayName }
					self.tableView.reloadData()
				}
			}
		}
	}

	private func showError(_ error: Error, title: String) {
		let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default))
		present(alert, animated: true)
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
