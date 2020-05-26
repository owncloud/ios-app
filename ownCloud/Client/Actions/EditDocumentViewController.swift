//
//  EditDocumentViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 22.01.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import QuickLook

@available(iOS 13.0, *)
class EditDocumentViewController: QLPreviewController, Themeable {

	weak var core: OCCore?
	var item: OCItem
	var savingMode: QLPreviewItemEditingMode?
	var itemTracker: OCCoreItemTracking?
	var modifiedContentsURL: URL?
	var dismissedViewWithoutSaving: Bool = false

	var source: URL {
		didSet {
			if self.source != oldValue {
				OnMainThread {
					self.reloadData()
				}
			}
		}
	}

	init(with file: URL, item: OCItem, core: OCCore? = nil) {
		self.source = file
		self.core = core
		self.item = item

		super.init(nibName: nil, bundle: nil)

		self.dataSource = self
		self.delegate = self
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		Theme.shared.register(client: self, applyImmediately: true)

		if let core = core, let path = item.path {
			itemTracker = core.trackItem(atPath: path, trackingHandler: { [weak self, weak core](error, item, _) in
				if let item = item, let self = self {
					var refreshPreview = false

					if let core = core {
						if item.contentDifferent(than: self.item, in: core) {
							refreshPreview = true
						}
					}

					self.item = item

					if refreshPreview {
						OnMainThread {
							self.reloadData()
						}
					}
				} else if item == nil {

					OnMainThread {
						let alertController = ThemedAlertController(title: "File no longer exists".localized,
																	message: nil,
																	preferredStyle: .alert)

						alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (_) in
							self?.dismiss(animated: true, completion: nil)
						}))

						self?.present(alertController, animated: true, completion: nil)
					}

				} else if let error = error {
					OnMainThread {
						self?.present(error: error, title: "Saving edited file failed".localized)
					}
				}
			})
		}
	}

	@objc func dismissAnimated() {
		self.setEditing(false, animated: false)

		if savingMode == nil {
			requestsavingMode { (savingMode) in
				self.dismiss(animated: true) {
					if let modifiedContentsURL = self.modifiedContentsURL {
						self.saveModifiedContents(at: modifiedContentsURL, savingMode: savingMode)
					} else if let savingMode = self.savingMode, savingMode == .createCopy {
						self.saveModifiedContents(at: self.source, savingMode: savingMode)
					} else {
						self.dismissedViewWithoutSaving = true
					}
				}
			}
		} else {
			self.dismiss(animated: true) {
				if let modifiedContentsURL = self.modifiedContentsURL, let savingMode = self.savingMode {
					self.saveModifiedContents(at: modifiedContentsURL, savingMode: savingMode)
				} else if let savingMode = self.savingMode, savingMode == .createCopy {
					self.saveModifiedContents(at: self.source, savingMode: savingMode)
				} else {
					self.dismissedViewWithoutSaving = true
				}
			}
		}
	}

	func requestsavingMode(completion: ((QLPreviewItemEditingMode) -> Void)? = nil) {
		let alertController = ThemedAlertController(title: "Save File".localized,
													message: nil,
													preferredStyle: .alert)

		if item.permissions.contains(.writable) {
			alertController.addAction(UIAlertAction(title: "Overwrite original".localized, style: .default, handler: { (_) in
				self.savingMode = .updateContents

				completion?(.updateContents)
			}))
		}
		if let core = core, item.parentItem(from: core)?.permissions.contains(.createFile) == true {
			alertController.addAction(UIAlertAction(title: "Save as copy".localized, style: .default, handler: { (_) in
				self.savingMode = .createCopy

				completion?(.createCopy)
			}))
		}

		alertController.addAction(UIAlertAction(title: "Discard changes".localized, style: .destructive, handler: { (_) in
			self.savingMode = .disabled

			completion?(.disabled)
		}))

		self.present(alertController, animated: true, completion: nil)
	}

	func saveModifiedContents(at url: URL, savingMode: QLPreviewItemEditingMode) {
		switch savingMode {
		case .createCopy:
			if let core = core, let parentItem = item.parentItem(from: core) {
				self.core?.importFileNamed(item.name, at: parentItem, from: url, isSecurityScoped: true, options: [ .automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue, OCCoreOption.importByCopying : true], placeholderCompletionHandler: { (error, _) in
					if let error = error {
						self.present(error: error, title: "Saving edited file failed".localized)
					}
				}, resultHandler: nil)
			}
		case .updateContents:
			if let core = core, let parentItem = item.parentItem(from: core) {
				core.reportLocalModification(of: item, parentItem: parentItem, withContentsOfFileAt: url, isSecurityScoped: true, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: { (error, _) in
					if let error = error {
						self.present(error: error, title: "Saving edited file failed".localized)
					}
				}, resultHandler: nil)
			}
		default:
			break
		}
	}

	func present(error: Error, title: String) {
		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad() {
			presentationStyle = .alert
		}

		let alertController = ThemedAlertController(title: title,
													message: error.localizedDescription,
													preferredStyle: presentationStyle)

		alertController.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))

		self.present(alertController, animated: true, completion: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.navigationController?.navigationBar.backgroundColor = collection.navigationBarColors.backgroundColor
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}

@available(iOS 13.0, *)
extension EditDocumentViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
	func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return 1
	}

	func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
		return source as QLPreviewItem
	}

	func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
		return .createCopy
	}

	func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
	}

	func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
		self.modifiedContentsURL = modifiedContentsURL
		if self.dismissedViewWithoutSaving, let savingMode = self.savingMode {
			self.saveModifiedContents(at: modifiedContentsURL, savingMode: savingMode)
		}
	}
}
