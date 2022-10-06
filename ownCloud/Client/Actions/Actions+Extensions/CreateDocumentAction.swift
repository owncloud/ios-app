//
//  CreateDocumentAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 07.09.22.
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
import ownCloudAppShared

class CreateDocumentAction: Action {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.createDocument") }
	override open class var category : ActionCategory? { return .normal }
	override open class var name : String? { return "New document".localized }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .keyboardShortcut, .emptyFolder] }
	override open class var keyCommand : String? { return "N" }
	override open class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != OCItemType.collection {
			return .none
		}

		if forContext.items.first?.permissions.contains(.createFile) == false {
			return .none
		}

		if forContext.core?.appProvider?.types?.contains(where: { fileType in
			return fileType.allowCreation
		}) == true {
			return .first
		}

		return .none
	}

	// MARK: - Action implementation
	override open func run() {
		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		let item = context.items.first

		guard item != nil, let itemLocation = item?.location else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let viewController = context.viewController else {
			completed(with: NSError(ocError: .internal))
			return
		}

		guard let documentTypes = context.core?.appProvider?.types?.filter({ fileType in
			return fileType.allowCreation
		}).sorted(by: { (type1, type2) in
			if let name1 = type1.name, let name2 = type2.name {
				return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
			}
			return false
		}), documentTypes.count > 0 else {
			completed()
			return
		}

		OnMainThread {
			let documentTypesDataSource = OCDataSourceArray()
			let documentTypesSection = CollectionViewSection(identifier: "documentTypes", dataSource: documentTypesDataSource, cellStyle: .init(with: .fillSpace), cellLayout: .fullWidth(itemHeightDimension: .estimated(54), groupHeightDimension: .estimated(54), edgeSpacing: NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(10), trailing: .fixed(0), bottom: .fixed(10)), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)), clientContext: self.context.clientContext)
			let documentPickerViewController = CollectionViewController(context: self.context.clientContext, sections: [ documentTypesSection ])

			let navigationViewController = ThemeNavigationController(rootViewController: documentPickerViewController)
			navigationViewController.modalPresentationStyle = .formSheet
			viewController.present(navigationViewController, animated: true)

			documentPickerViewController.title = "New document".localized
			documentPickerViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction(handler: { [weak navigationViewController] action in
				navigationViewController?.dismiss(animated: true)
				self.completed()
			}), menu: nil)

			let createDocument : (OCAppProviderFileType) -> Void = { (fileType) in
				guard let core = self.core, let parentItem = try? core.cachedItem(at: itemLocation) else {
					self.completed()
					return
				}

				core.suggestUnusedNameBased(on: "New document".localized.appending((fileType.extension != nil) ? ".\(fileType.extension!)" : ""), at: itemLocation, isDirectory: false, using: .numbered, filteredBy: nil, resultHandler: { (suggestedName, _) in
					guard let suggestedName = suggestedName else { return }

					OnMainThread {
						let documentNameViewController = NamingViewController( with: self.core, defaultName: suggestedName, stringValidator: { name in
							if name.contains("/") || name.contains("\\") {
								return (false, nil, "File name cannot contain / or \\".localized)
							} else {
								if let item = item {
									if ((try? self.core?.cachedItem(inParent: item, withName: name, isDirectory: true)) != nil) ||
									   ((try? self.core?.cachedItem(inParent: item, withName: name, isDirectory: false)) != nil) {
										return (false, "Item with same name already exists".localized, "An item with the same name already exists in this location.".localized)
									}
								}

								return (true, nil, nil)
							}
						}, completion: { newFileName, _ in
							guard let newFileName = newFileName, let core = self.core else {
								self.completed()
								return
							}

							if let progress = core.connection.createAppFile(of: fileType, in: parentItem, withName: newFileName, completionHandler: { (error, fileID, item) in
								if let error = error {
									OnMainThread {
										let alertController = ThemedAlertController(
											with: "Error creating {{itemName}}".localized(["itemName" : newFileName]),
											message: error.localizedDescription,
											okLabel: "OK".localized,
											action: nil)

										viewController.present(alertController, animated: true)

										self.completed(with: error)
									}

									return
								}

								if error == nil, let query = self.context.clientContext?.query {
									self.core?.reload(query)
								}

								self.completed(with: error)
							}) {
								self.publish(progress: progress)
							}
						})

						documentNameViewController.navigationItem.title = "Pick a name".localized

						navigationViewController.pushViewController(documentNameViewController, animated: true)
					}
				})
			}

			let fallbackIcon = UIImage(systemName: "doc")?.withRenderingMode(.alwaysTemplate)
			let iconSize = CGSize(width: 36, height: 36)

			let headerItem = OCDataItemPresentable(reference: "_header" as NSString, originalDataItemType: nil, version: nil)
			headerItem.title = "Pick a document type to create:".localized
			headerItem.childrenDataSourceProvider = nil

			var documentTypeActions : [OCDataItem & OCDataItemVersioning] = [ headerItem ]

			for documentType in documentTypes {
				if let documentTypeName = documentType.name {
					var docIcon : UIImage?

					if let docTypeIcon = documentType.icon {
						docIcon = docTypeIcon
					} else if let mimeType = documentType.mimeType, let tvgIconName = OCItem.iconName(for: mimeType) {
						docIcon = Theme.shared.image(for: tvgIconName, size: iconSize)
					}

					if docIcon == nil {
						docIcon = fallbackIcon
					}

					docIcon = docIcon?.paddedTo(width: iconSize.width, height: iconSize.height)

					let action = OCAction(title: documentTypeName, icon: docIcon, action: { action, options, completionHandler in
						createDocument(documentType)
					})

					documentTypeActions.append(action)
				}
			}

			documentTypesDataSource.setVersionedItems(documentTypeActions)
		}
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "doc.badge.plus")?.withRenderingMode(.alwaysTemplate)
	}
}
