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
protocol EditDocumentViewControllerDelegate: class {
	func editDocumentViewControllerDidDismiss(_ controller: EditDocumentViewController)
}

@available(iOS 13.0, *)
class EditDocumentViewController: QLPreviewController, Themeable {

	weak var core: OCCore?
	var item: OCItem
	var editDelegte: EditDocumentViewControllerDelegate?
	var handleSaving: QLPreviewItemEditingMode?

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
	}

	@objc func dismissAnimated() {
		self.setEditing(false, animated: false)

		if handleSaving == nil {
			requestHandleSaving { (_) in
				self.dismiss(animated: true, completion: nil)
			}
		} else {
			self.dismiss(animated: true, completion: nil)
		}
	}

	func requestHandleSaving(completion: ((QLPreviewItemEditingMode) -> Void)? = nil) {
		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad() {
			presentationStyle = .alert
		}

		let alertController = ThemedAlertController(title: "How should this file be saved?".localized,
													message: nil,
													preferredStyle: presentationStyle)
		alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

		alertController.addAction(UIAlertAction(title: "Overwrite originale".localized, style: .default, handler: { (_) in
			self.handleSaving = .updateContents

			completion?(.updateContents)
		}))

		alertController.addAction(UIAlertAction(title: "Save as copy".localized, style: .default, handler: { (_) in
			self.handleSaving = .createCopy

			completion?(.createCopy)

		}))

		alertController.addAction(UIAlertAction(title: "Discard changes".localized, style: .destructive, handler: { (_) in
			self.handleSaving = .disabled

			completion?(.disabled)
		}))

		self.present(alertController, animated: true, completion: nil)
	}

	func saveModifiedContents(at url: URL, handleSaving: QLPreviewItemEditingMode) {
		switch handleSaving {
		case .createCopy:
			if let core = core, let parentItem = item.parentItem(from: core) {
				self.core?.importFileNamed(item.name, at: parentItem, from: url, isSecurityScoped: false, options: [ .automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue ], placeholderCompletionHandler: nil, resultHandler: nil)
			}
		case .updateContents:
			if let core = core, let parentItem = item.parentItem(from: core) {
				core.reportLocalModification(of: item, parentItem: parentItem, withContentsOfFileAt: url, isSecurityScoped: false, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: nil, resultHandler: nil)
			}
		default:
			break
		}
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

	func previewControllerDidDismiss(_ controller: QLPreviewController) {
		self.editDelegte?.editDocumentViewControllerDidDismiss(self)
	}

	func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
		return .createCopy
    }

    func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
    }

    func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
		if let handleSaving = handleSaving {
			saveModifiedContents(at: modifiedContentsURL, handleSaving: handleSaving)
		} else {
			requestHandleSaving { (handleSaving) in
				self.saveModifiedContents(at: modifiedContentsURL, handleSaving: handleSaving)
			}
		}
	}
}
