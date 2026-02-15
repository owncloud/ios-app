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

public extension OCClassSettingsKey {
	static let createDocumentMode = OCClassSettingsKey("create-document-mode")
}

public enum CreateDocumentActionMode: String {
	case create = "create"
	case createAndOpen = "create-and-open"
}

class CreateDocumentAction: Action {
	public static func registerSettings() {
		self.registerOCClassSettingsDefaults([
			.createDocumentMode : CreateDocumentActionMode.createAndOpen.rawValue
		], metadata: [
			.createDocumentMode : [
				.type 		: OCClassSettingsMetadataType.string,
				.label		: "Create Document Mode",
				.description 	: "Determines behaviour when creating a document.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Actions",
				.possibleValues : [
					[
						OCClassSettingsMetadataKey.value 	: CreateDocumentActionMode.create.rawValue,
						OCClassSettingsMetadataKey.description 	: "Creates the document."
					],
					[
						OCClassSettingsMetadataKey.value 	: CreateDocumentActionMode.createAndOpen.rawValue,
						OCClassSettingsMetadataKey.description 	: "Creates the document and opens it in a web app for the document format."
					]
				]
			]
		])
	}

	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.createDocument") }
	override open class var category : ActionCategory? { return .normal }
	override open class var name : String? { return OCLocalizedString("New document", nil) }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.folderAction, .keyboardShortcut, .emptyFolder] }
	override open class var keyCommand : String? { return "N" }
	override open class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .shift] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != .collection {
			return .none
		}

		if forContext.items.first?.permissions.contains(.createFile) == false {
			return .none
		}

		if let appProvider = forContext.core?.appProvider, appProvider.supportsCreateDocument {
			if appProvider.types?.contains(where: { fileType in
				return fileType.allowCreation
			}) == true {
				return .first
			}
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

		var createMode : CreateDocumentActionMode = .createAndOpen

		if let createModeString = classSetting(forOCClassSettingsKey: .createDocumentMode) as? String, let configuredCreateMode = CreateDocumentActionMode(rawValue: createModeString) {
			createMode = configuredCreateMode
		}

		OnMainThread {
			let documentTypesDataSource = OCDataSourceArray()
			let documentTypesSection = CollectionViewSection(identifier: "documentTypes", dataSource: documentTypesDataSource, cellStyle: .init(with: .fillSpace), cellLayout: .fullWidth(itemHeightDimension: .estimated(54), groupHeightDimension: .estimated(54), edgeSpacing: NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(10), trailing: .fixed(0), bottom: .fixed(10)), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)), clientContext: self.context.clientContext)
			let documentPickerViewController = CollectionViewController(context: self.context.clientContext, sections: [ documentTypesSection ])

			let navigationViewController = ThemeNavigationController(rootViewController: documentPickerViewController)
			navigationViewController.modalPresentationStyle = .formSheet
			viewController.present(navigationViewController, animated: true)

			documentPickerViewController.title = OCLocalizedString("New document", nil)
			documentPickerViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction(handler: { [weak navigationViewController] action in
				navigationViewController?.dismiss(animated: true)
				self.completed()
			}), menu: nil)

			let createDocument : (OCAppProviderFileType) -> Void = { (fileType) in
				guard let core = self.core, let parentItem = try? core.cachedItem(at: itemLocation) else {
					self.completed()
					return
				}

				core.suggestUnusedNameBased(on: OCLocalizedString("New document", nil).appending((fileType.extension != nil) ? ".\(fileType.extension!)" : ""), at: itemLocation, isDirectory: false, using: .numbered, filteredBy: nil, resultHandler: { (suggestedName, _) in
					guard let suggestedName = suggestedName else { return }

					let fallbackIcon = (fileType.mimeType != nil) ? ResourceItemIcon.iconFor(mimeType: fileType.mimeType!, fileName: fileType.extension != nil ? "file.\(fileType.extension!)" : nil) : .file

					OnMainThread {
						let documentNameViewController = NamingViewController( with: self.core, defaultName: suggestedName, stringValidator: { name in
							if name.contains("/") || name.contains("\\") {
								return (false, nil, OCLocalizedString("File name cannot contain / or \\", nil))
							} else {
								if let item = item {
									if ((try? self.core?.cachedItem(inParent: item, withName: name, isDirectory: true)) != nil) ||
									   ((try? self.core?.cachedItem(inParent: item, withName: name, isDirectory: false)) != nil) {
										return (false, OCLocalizedString("Item with same name already exists", nil), OCLocalizedString("An item with the same name already exists in this location.", nil))
									}
								}

								return (true, nil, nil)
							}
						}, fallbackIcon: fallbackIcon, completion: { newFileName, _ in
							guard let newFileName = newFileName, let core = self.core else {
								self.completed()
								return
							}

							if let progress = core.connection.createAppFile(of: fileType, in: parentItem, withName: newFileName, completionHandler: { (error, fileID, item) in
								if let error {
									OnMainThread {
										let alertController = ThemedAlertController(
											with: OCLocalizedFormat("Error creating {{itemName}}", ["itemName" : newFileName]),
											message: error.localizedDescription,
											okLabel: OCLocalizedString("OK", nil),
											action: nil)

										viewController.present(alertController, animated: true)

										self.completed(with: error)
									}

									return
								}

								if let query = self.context.clientContext?.query {
									self.core?.reload(query)
								}

								switch createMode {
									case .create: break
									case .createAndOpen:
										if let fileID {
											let tokenStorage = NSMutableArray()
											var requirements: [OCQueryCondition] = [
												.where(.fileID, isEqualTo: fileID)
											]

											if let driveID = itemLocation.driveID {
												requirements.append(.where(.driveID, isEqualTo: driveID))
											}

											OnMainThread {
												let progressHUDViewController = ProgressHUDViewController(on: viewController, label: OCLocalizedString("Opening…", nil))

												if let trackingToken = core.trackItem(with: .require(requirements), trackingHandler: { [weak self] error, item, isInitial in
													if error != nil {
														// Error
														OnMainThread {
															progressHUDViewController.dismiss(completion: nil)
														}

														// End item tracking
														OCSynchronized(viewController) {
															tokenStorage.removeAllObjects()
														}
													} else if let item {
														// Open in web app
														OnMainThread {
															progressHUDViewController.dismiss(completion: {
																if let context = self?.context, let core = context.core, let viewController = context.viewController, let openInWebAppActionIdentifier = OpenInWebAppAction.identifier {
																	let actionContext = ActionContext(viewController: viewController, clientContext: context.clientContext, core: core, items: [item], location: OCExtensionLocation(ofType: .action, identifier: .moreItem), sender: nil)
																	let actions = Action.sortedApplicableActions(for: actionContext)

																	if let openAction = actions.first(where: { action in
																		type(of: action).identifier == openInWebAppActionIdentifier
																	}) {
																		openAction.run()
																	}
																}
															})
														}

														// End item tracking
														OCSynchronized(viewController) {
															tokenStorage.removeAllObjects()
														}
													}
												}) {
													OCSynchronized(viewController) {
														tokenStorage.add(trackingToken)
													}

													OnMainThread(after: 10, {
														if tokenStorage.count > 0 {
															progressHUDViewController.dismiss(completion: nil)

															// End item tracking
															tokenStorage.removeAllObjects()
														}
													})
												}
											}
										}
								}

								self.completed(with: error)
							}) {
								self.publish(progress: progress)
							}
						})

						documentNameViewController.requiredFileExtension = fileType.extension
						documentNameViewController.navigationItem.title = OCLocalizedString("Pick a name", nil)

						navigationViewController.pushViewController(documentNameViewController, animated: true)
					}
				})
			}

			let fallbackIcon = UIImage(systemName: "doc")?.withRenderingMode(.alwaysTemplate)
			let iconSize = CGSize(width: 36, height: 36)

			let headerItem = OCDataItemPresentable(reference: "_header" as NSString, originalDataItemType: nil, version: nil)
			headerItem.title = OCLocalizedString("Pick a document type to create:", nil)
			headerItem.childrenDataSourceProvider = nil

			var documentTypeActions : [OCDataItem & OCDataItemVersioning] = [ headerItem ]

			for documentType in documentTypes {
				if let documentTypeName = documentType.name {
					var docIcon : UIImage?

					if let docTypeIcon = documentType.icon {
						docIcon = docTypeIcon
					} else if let mimeType = documentType.mimeType, let tvgIconName = OCItem.iconName(for: mimeType, fileName: documentType.extension != nil ? "file.\(documentType.extension!)" : nil) {
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
