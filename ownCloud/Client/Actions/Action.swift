//
//  Action.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

typealias ActionCompletion = ((_ item: OCItem, _ core: OCCore, _ vcToPresent: UIViewController) -> Void)?

enum Result<T> {
	case failure(Error)
	case sucess(T)
}

enum ActionType {
	case destructive
	case regular
}

struct Action {
	var name: String
	var type: ActionType
	var completion: ActionCompletion

	init(with name: String, completion: ActionCompletion, type: ActionType) {
		self.name = name
		self.completion = completion
		self.type = type

	}
}

class ActionsMoreViewController: NSObject {

	weak var vcToPresentIn: UIViewController?
	var moreViewController: UIViewController?
	var core: OCCore
	var item: OCItem

	var interactionController: UIDocumentInteractionController?

	init (item: OCItem, core: OCCore, into viewController: UIViewController) {
		self.vcToPresentIn = viewController
		self.core = core
		self.item = item
		super.init()
	}

	func presentActionsCard(with actions: [Action], completion: () -> Void) {
		self.moreViewController = actionsViewController(with: actions, for: item, core: core)
		vcToPresentIn?.present(asCard: moreViewController!, animated: true)
	}

	func actionsViewController(with actions: [Action], for item: OCItem, core: OCCore) -> MoreViewController {

		let header = MoreViewHeader(for: item, with: core)
		let tableViewController = MoreStaticTableViewController(style: .grouped)
		let moreViewController: MoreViewController = MoreViewController(item: item, core: core, header: header, viewController: tableViewController)

		var rows: [StaticTableViewRow] = []

		for action in actions {

			var style: StaticTableViewRowButtonStyle
			switch action.type {
			case .destructive:
				style = .destructive
			default:
				style = .plainNonOpaque
			}

			let row: StaticTableViewRow = StaticTableViewRow(buttonWithAction: { (_, _) in
				moreViewController.dismiss(animated: true, completion: {
					action.completion?(item, core, self.vcToPresentIn!)
				})
			}, title: action.name, style: style)

			rows.append(row)
		}

		let title = NSAttributedString(string: "Actions".localized, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		let section = MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: rows)

		tableViewController.addSection(section)
		return moreViewController
	}

	var openIn: Action {
		let action = Action(with: "Open in".localized, completion: { (item, core, vcToPresentIn) in
			let controller = DownloadFileProgressHUDViewController()
			controller.present(on: vcToPresentIn)

			if let downloadProgress = core.downloadItem(item, options: nil, resultHandler: { (error, _, _, file) in
				if error != nil {
					Log.log("Error \(String(describing: error)) downloading \(String(describing: item.path)) in openIn function")
				} else {
					controller.dismiss(animated: true, completion: {
						self.interactionController = UIDocumentInteractionController(url: file!.url)
						self.interactionController?.presentOptionsMenu(from: .zero, in: vcToPresentIn.view, animated: true)
					})
				}
			}) {
				controller.attach(progress: downloadProgress)
			} else {
				let alert = UIAlertController(with: "No Network connection", message: "No network connection")
				vcToPresentIn.present(alert, animated: true)
			}
		}, type: .regular)
		return action
	}

	var duplicate: Action {
		let action = Action(with: "Duplicate", completion: { (item, core, viewcontroller) in

			guard let viewController = viewcontroller as? ClientQueryViewController else {
				return
			}

			var name: String = "\(item.name!) copy"

			if item.type != .collection {
				let itemName = item.nameWithoutExtension()
				var fileExtension = item.fileExtension()

				if fileExtension != "" {
					fileExtension = ".\(fileExtension)"
				}

				name = "\(itemName) copy\(fileExtension)"
			}

			if let progress = core.copy(item, to: viewController.query?.rootItem, withName: name, options: nil, resultHandler: { (error, _, item, _) in
				if error != nil {
					Log.log("Error \(String(describing: error)) deleting \(String(describing: item?.path))")
				}
			}) {
				viewController.progressSummarizer?.startTracking(progress: progress)
			}

		}, type: .regular)

		return action
	}

	var move: Action {
		let action = Action(with: "Move".localized, completion: { (item, core, viewController) in

			guard let viewController = viewController as? ClientQueryViewController else {
				return
			}

			let directoryPickerVC = ClientDirectoryPickerViewController(core: core, path: "/", completion: { (selectedDirectory) in

				if let progress = core.move(item, to: selectedDirectory, withName: item.name, options: nil, resultHandler: { (error, _, _, _) in
					if error != nil {
						Log.log("Error \(String(describing: error)) moving \(String(describing: item.path))")
					} else {
					}
				}) {
					viewController.progressSummarizer?.startTracking(progress: progress)
				}
			})

			let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerVC)
			viewController.navigationController?.present(pickerNavigationController, animated: true)
		}, type: .regular)

		return action
	}

	var delete: Action {
		let action = Action(with: "Delete".localized, completion: { (item, core, viewController) in
			let alertController = UIAlertController(
				with: item.name!,
				message: "Are you sure you want to delete this item from the server?".localized,
				destructiveLabel: "Delete".localized,
				preferredStyle: UIDevice.current.isIpad() ? UIAlertControllerStyle.alert : UIAlertControllerStyle.actionSheet,
				destructiveAction: {
					if let progress = core.delete(item, requireMatch: true, resultHandler: { (error, _, _, _) in
						if error != nil {
							Log.log("Error \(String(describing: error)) deleting \(String(describing: item.path))")
						}
					}) {
						if let viewController = viewController as? ClientQueryViewController {
							viewController.progressSummarizer?.startTracking(progress: progress)
						} else {
							viewController.dismiss(animated: true)
						}
					}
			})

			viewController.present(alertController, animated: true)
		}, type: .destructive)

		return action
	}
}

extension ActionsMoreViewController: UIDocumentInteractionControllerDelegate {
	func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
		self.interactionController = nil
	}
}
