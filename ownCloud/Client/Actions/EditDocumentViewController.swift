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
import ownCloudAppShared
import QuickLook

@available(iOS 13.0, *)
class EditDocumentViewController: QLPreviewController, Themeable {

	weak var core: OCCore?
	var item: OCItem
	var savingMode: QLPreviewItemEditingMode?
	var itemTracker: OCCoreItemTracking?
	var modifiedContentsURL: URL?
	var dismissedViewWithoutSaving: Bool = false
	var timer: DispatchSourceTimer?
	var pdfViewController : PDFViewerViewController?

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

		if let core = core, let location = item.location {
			itemTracker = core.trackItem(at: location, trackingHandler: { [weak self, weak core](error, item, _) in
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
						let alertController = ThemedAlertController(title: OCLocalizedString("File no longer exists", nil),
																	message: nil,
																	preferredStyle: .alert)

						alertController.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default, handler: { (_) in
							self?.dismiss(animated: true, completion: nil)
						}))

						self?.present(alertController, animated: true, completion: nil)
					}

				} else if let error = error {
					OnMainThread {
						self?.present(error: error, title: OCLocalizedString("Saving edited file failed", nil))
					}
				}
			})
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
		timer = nil
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let queue = DispatchQueue(label: "com.owncloud.edit-document-queue")
		timer = DispatchSource.makeTimerSource(queue: queue)
		timer!.schedule(deadline: .now(), repeating: .seconds(1))
		timer!.setEventHandler { [weak self] in
			OnMainThread {
				if self?.navigationItem.rightBarButtonItems?.count ?? 0 > 1 || !(self?.navigationController?.isToolbarHidden ?? false) {
					self?.timer = nil
					self?.enableEditingMode()
				}
			}
		}
		timer!.resume()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.view.secureView(core: core)
	}

	private func findAndTriggerBarItem(containing substring: String) -> Bool {
		var barButtonItems: [UIBarButtonItem]?

		if let rightBarButtonItems = navigationItem.rightBarButtonItems, rightBarButtonItems.count > 0 {
			barButtonItems = rightBarButtonItems
		} else if let toolbarItems = self.toolbarItems, toolbarItems.count > 0 {
			barButtonItems = toolbarItems
		}

		if let barButtonItems {
			for markupButton in barButtonItems {
				if (markupButton.debugDescription as NSString).contains(substring) {
					_ = markupButton.target?.perform(markupButton.action, with: markupButton)
					return true
				}
			}
		}

		return false
	}

	private func findView(from view: UIView, containing substring: String) -> UIView? {
		if (view.debugDescription as NSString).contains(substring) {
			return view
		}
		for subview in view.subviews {
			if let foundView = findView(from: subview, containing: substring) {
				return foundView
			}
		}

		return nil
	}

	private var enableRetries = 0

	@objc func enableEditingMode() {
		// Activate editing mode by performing the action on pencil icon. Unfortunately that's the only way to do it apparently
		let pencilIconName = "pencil.tip.crop.circle"
		if #available(iOS 26.0, *) {
			if let navigationControllerView = navigationController?.view,
			   let markupButton = findView(from: navigationControllerView, containing: pencilIconName) as? UIControl {
				// On iOS 26, in narrow sizes (e.g. iPhone) the edit button is located in a floating bar on the bottom of the screen
				markupButton.sendActions(for: .primaryActionTriggered)
			} else if findAndTriggerBarItem(containing: pencilIconName) {
				// On iOS 26, in wide sizes (e.g. iPad), the edit button continues to reside in the navigation bar
				// If we arrive here, triggering it was successful
			} else if enableRetries < 10 {
				// If action fails, retry for up to 10 times
				//
				// This can be necessary because on iOS 26 the document and UI isn't shown right away, but an additional
				// transition is shown by iOS. Hard to tell if this is a bug in a rough iOS 26.0 or intentional - we
				// need to deal with it either way.
				enableRetries += 1

				Log.debug("Retry \(enableRetries) enabling editing mode")

				OnMainThread(after: 0.2) { [weak self] in
					self?.enableEditingMode()
				}
			}
		} else if #available(iOS 16.0, *) {
			_ = findAndTriggerBarItem(containing: pencilIconName)
		} else if #available(iOS 15.0, *) {
			if self.navigationItem.rightBarButtonItems?.count ?? 0 > 2 {
				guard let markupButton = self.navigationItem.rightBarButtonItems?[1] else { return }
				_ = markupButton.target?.perform(markupButton.action, with: markupButton)
			} else if UIDevice.current.isIpad, self.navigationItem.rightBarButtonItems?.count ?? 0 == 2 {
				guard let markupButton = self.navigationItem.rightBarButtonItems?[1] else { return }
				_ = markupButton.target?.perform(markupButton.action, with: markupButton)
			} else {
				guard let markupButton = self.navigationItem.rightBarButtonItems?.first else { return }
				_ = markupButton.target?.perform(markupButton.action, with: markupButton)
			}
		}
	}

	func disableEditingMode() {
		if #available(iOS 17.0, *) {
			if let rightBarButtonItems = self.navigationItem.rightBarButtonItems, rightBarButtonItems.count > 0 {
				for markupButton in rightBarButtonItems {
					if (markupButton.debugDescription as NSString).contains("pencil.tip.crop.circle") {
						_ = markupButton.target?.perform(markupButton.action, with: markupButton)
					}
				}
			}
		} else {
			self.setEditing(false, animated: false)
		}
	}

	@objc func dismissAnimated() {
		disableEditingMode()

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
		let alertController = ThemedAlertController(title: OCLocalizedString("Save File", nil),
													message: nil,
													preferredStyle: .alert)

		if item.permissions.contains(.writable) {
			alertController.addAction(UIAlertAction(title: OCLocalizedString("Overwrite original", nil), style: .default, handler: { (_) in
				self.savingMode = .updateContents

				completion?(.updateContents)
			}))
		}
		if let core = core, item.parentItem(from: core)?.permissions.contains(.createFile) == true {
			alertController.addAction(UIAlertAction(title: OCLocalizedString("Save as copy", nil), style: .default, handler: { (_) in
				self.savingMode = .createCopy

				completion?(.createCopy)
			}))
		}

		alertController.addAction(UIAlertAction(title: OCLocalizedString("Discard changes", nil), style: .destructive, handler: { (_) in
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
						self.present(error: error, title: OCLocalizedString("Saving edited file failed", nil))
					}
				}, resultHandler: nil)
			}
		case .updateContents:
			if let core = core, let parentItem = item.parentItem(from: core) {
				pdfViewController?.allowUpdatesUntilLocalModificationPersists = true

				core.reportLocalModification(of: item, parentItem: parentItem, withContentsOfFileAt: url, isSecurityScoped: true, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: { (error, _) in
					if let error = error {
						self.present(error: error, title: OCLocalizedString("Saving edited file failed", nil))
					}
				}, resultHandler: nil)
			}
		default:
			break
		}
	}

	func present(error: Error, title: String) {
		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad {
			presentationStyle = .alert
		}

		let alertController = ThemedAlertController(title: title,
													message: error.localizedDescription,
													preferredStyle: presentationStyle)

		alertController.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .cancel, handler: nil))

		self.present(alertController, animated: true, completion: nil)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.navigationController?.navigationBar.applyThemeCollection(collection)
		self.view.backgroundColor = collection.css.getColor(.fill, selectors: [.table], for: self.view)
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
