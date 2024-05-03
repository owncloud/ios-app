//
//  CreateShortcutFileViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.04.24.
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
import ownCloudAppShared
import ownCloudSDK

class CreateShortcutFileViewController: CollectionViewController {
	var parentItem: OCItem

	var targetSectionDatasource: OCDataSourceArray = OCDataSourceArray()
	var targetFieldSpacerView: UIView

	var targetURLTextField: UITextField?
	var targetURLString: String? {
		didSet {
			updateState()
		}
	}
	var targetItem: OCItem? {
		didSet {
			if targetItem == nil {
				if let oldBaseName = oldValue?.baseName, name == oldBaseName {
					nameTextField?.text = ""
					name = nil
				}

				targetSectionDatasource.setVersionedItems([targetFieldSpacerView, pickAnItemAction])
			} else {
				if let core = clientContext?.core, let targetItem {
					let itemView = MoreViewHeader(for: targetItem, with: core)
					itemView.translatesAutoresizingMaskIntoConstraints = false

					let containerView = UIView()
					containerView.translatesAutoresizingMaskIntoConstraints = false

					let clearButton = UIButton(configuration: .plain())
					clearButton.translatesAutoresizingMaskIntoConstraints = false
					clearButton.setImage(OCSymbol.icon(forSymbolName: "xmark.circle.fill"), for: .normal)
					clearButton.addAction(UIAction(handler: { [weak self]_ in
						self?.targetItem = nil

						self?.targetURLTextField?.text = ""
						self?.targetURLString = nil
					}), for: .primaryActionTriggered)
					clearButton.accessibilityLabel = "Clear".localized

					containerView.embed(toFillWith: itemView, insets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
					containerView.addSubview(clearButton)

					NSLayoutConstraint.activate([
						clearButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
						clearButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
					])

					targetSectionDatasource.setVersionedItems([containerView])

					if name == "" || name == nil {
						var baseName = targetItem.baseName

						if targetItem.isRoot {
							if core.useDrives, let driveID = targetItem.driveID {
								if let drive = core.drive(withIdentifier: driveID, attachedOnly: false) {
									baseName = drive.name
								}
							} else {
								baseName = "Files".localized
							}
						}

						if let baseName {
							nameTextField?.text = baseName
							name = baseName
						}
					}
				}
			}
		}
	}

	var nameTextField: UITextField?
	var name: String? {
		didSet {
			updateState()
		}
	}

	lazy var pickAnItemAction: OCAction = {
		return OCAction(title: "Pick file or folder".localized, icon: OCSymbol.icon(forSymbolName: "list.bullet.rectangle"), action: { [weak self] action, options, completion in
			self?.pickAnItem()
			completion(nil)
		})
	}()

	var bottomButtonBar: BottomButtonBar?

	init(parentItem: OCItem, clientContext: ClientContext) {
		var sections: [CollectionViewSection] = []

		self.parentItem = parentItem

		// Managament section cell style
		let managementCellStyle: CollectionViewCellStyle = .init(with: .tableCell)

		// Adapted context
		let controllerContext = ClientContext(with: clientContext)
		controllerContext.postInitializationModifier = { (owner, context) in
			context.originatingViewController = owner as? UIViewController
		}

		// Target
		let textFieldSpacing = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
		let targetURLTextField : UITextField = ThemeCSSTextField()
		targetURLTextField.keyboardType = .URL
		targetURLTextField.translatesAutoresizingMaskIntoConstraints = false
		targetURLTextField.setContentHuggingPriority(.required, for: .vertical)
		targetURLTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		targetURLTextField.placeholder = "URL".localized
		targetURLTextField.accessibilityLabel = "URL".localized
		targetURLTextField.clearButtonMode = .always

		self.targetURLTextField = targetURLTextField

		self.targetFieldSpacerView = UIView()
		self.targetFieldSpacerView.translatesAutoresizingMaskIntoConstraints = false
		self.targetFieldSpacerView.embed(toFillWith: targetURLTextField, insets: textFieldSpacing)

		// Target actions
		let targetSection = CollectionViewSection(identifier: "target", dataSource: targetSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: controllerContext)
		targetSection.boundarySupplementaryItems = [
			.mediumTitle("URL of webpage or item".localized)
		]

		sections.append(targetSection)

		// Name text field
		let nameTextField : UITextField = ThemeCSSTextField()
		nameTextField.translatesAutoresizingMaskIntoConstraints = false
		nameTextField.setContentHuggingPriority(.required, for: .vertical)
		nameTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		nameTextField.placeholder = "Name".localized
		nameTextField.accessibilityLabel = "Name".localized
		nameTextField.clearButtonMode = .always

		self.nameTextField = nameTextField

		let nameSpacerView = UIView()
		nameSpacerView.translatesAutoresizingMaskIntoConstraints = false
		nameSpacerView.embed(toFillWith: nameTextField, insets: textFieldSpacing)

		let nameSectionDatasource = OCDataSourceArray(items: [nameSpacerView])
		let nameSection = CollectionViewSection(identifier: "name", dataSource: nameSectionDatasource, cellStyle: managementCellStyle, cellLayout: .list(appearance: .insetGrouped, contentInsets: .insetGroupedSectionInsets), clientContext: controllerContext)
		nameSection.boundarySupplementaryItems = [
			.mediumTitle("Name".localized)
		]

		sections.append(nameSection)

		super.init(context: controllerContext, sections: sections, useStackViewRoot: true, compressForKeyboard: true)

		self.cssSelector = .grouped

		targetSectionDatasource.setVersionedItems([targetFieldSpacerView, pickAnItemAction])

		revoke(in: clientContext, when: [ .connectionClosed, .connectionOffline ])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		// Set navigation bar title
		navigationItem.titleLabelText = "Create shortcut".localized

		// Add bottom button bar
		bottomButtonBar = BottomButtonBar(selectButtonTitle: "Create shortcut".localized, cancelButtonTitle: "Cancel".localized, hasCancelButton: true, selectAction: UIAction(handler: { [weak self] _ in
			self?.createLink()
		}), cancelAction: UIAction(handler: { [weak self] _ in
			self?.completed()
		}))

		let bottomButtonBarViewController = UIViewController()
		bottomButtonBarViewController.view = bottomButtonBar

		self.addStacked(child: bottomButtonBarViewController, position: .bottom)

		// Wire up name textfield
		nameTextField?.addAction(UIAction(handler: { [weak self, weak nameTextField] _ in
			if let nameTextField {
				self?.name = nameTextField.text
			}
		}), for: .allEditingEvents)

		// Wire up URL textfield
		targetURLTextField?.addAction(UIAction(handler: { [weak self, weak targetURLTextField] _ in
			if let targetURLTextField {
				self?.targetURLString = targetURLTextField.text
			}
		}), for: .allEditingEvents)

		updateState()
	}

	func pickAnItem() {
		guard let bookmark = clientContext?.core?.bookmark, let clientContext else {
			return
		}
		let locationPicker = ClientLocationPicker(location: .account(bookmark), selectButtonTitle: "Select".localized, headerTitle: "Pick file or folder".localized, headerSubTitle: nil, requiredPermissions: [], avoidConflictsWith: nil, choiceHandler: { [weak self] (selectedItem, location, _, cancelled) in
			guard !cancelled, let selectedItem else {
				return
			}
			self?.fetchURL(forItem: selectedItem)
		})
		locationPicker.allowFileSelection = true

		locationPicker.present(in: clientContext)
	}

	func fetchURL(forItem item: OCItem) {
		guard let core = clientContext?.core else {
			return
		}

		core.retrievePrivateLink(for: item, completionHandler: { [weak self] error, privateLinkURL in
			if let error {
				OnMainThread {
					let alertController = ThemedAlertController(with: "Error".localized, message: error.localizedDescription, okLabel: "OK".localized, action: nil)
					self?.clientContext?.present(alertController, animated: true)
				}
				return
			}

			OnMainThread {
				self?.targetURLString = privateLinkURL?.absoluteString
				self?.targetURLTextField?.text = self?.targetURLString ?? ""
				self?.targetItem = item
			}
		})
	}

	func updateState() {
		var createIsEnabled = false

		if let name, name.count > 0, let targetURLString, targetURLString.count > 0 {
			createIsEnabled = true
		}

		bottomButtonBar?.selectButton.isEnabled = createIsEnabled
	}

	func createLink() {
		var urlString = self.targetURLString

		if let urlStringIn = urlString,
		   urlStringIn.lowercased().hasPrefix("http://") == false,
		   urlStringIn.lowercased().hasPrefix("https://") == false {
			urlString = "https://".appending(urlStringIn)
		}

		if let name, let urlString, let url = URL(string: urlString) {
			createURLShortcut(name: name, url: url)
		}
	}

	func createURLShortcut(name: String, url: URL) {
		guard let core = clientContext?.core else { return }

		if let urlFileData = INIFile.URLFile(with: url).data {
			if let temporaryFolderURL = core.vault.temporaryDownloadURL?.appendingPathComponent(UUID().uuidString) {
				let temporaryFileURL = temporaryFolderURL.appendingPathComponent("\(name).url")

				try? FileManager.default.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true)
				try? urlFileData.write(to: temporaryFileURL)

				core.importFileNamed("\(name).url", at: parentItem, from: temporaryFileURL, isSecurityScoped: false, placeholderCompletionHandler: { [weak self] error, item in
					try? FileManager.default.removeItem(at: temporaryFileURL)
					try? FileManager.default.removeItem(at: temporaryFolderURL)

					self?.completed(with: error)
				})
			} else {
				completed(with: NSError(ocError: .itemInsufficientPermissions))
			}
		} else {
			completed(with: NSError(ocError: .itemInsufficientPermissions))
		}
	}

	func completed(with error: Error? = nil) {
		OnMainThread(inline: true) {
			if let error {
				let alertController = ThemedAlertController(with: "Error".localized, message: error.localizedDescription, okLabel: "OK".localized, action: nil)
				self.clientContext?.present(alertController, animated: true)
			} else if self.presentingViewController != nil {
				self.dismiss(animated: true, completion: nil)
			}
		}
	}
}
