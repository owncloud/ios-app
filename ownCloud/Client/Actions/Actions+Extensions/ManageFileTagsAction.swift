//
//  ManageFileTagsAction.swift
//  ownCloud
//
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK
import ownCloudAppShared

class ManageFileTagsAction: Action {
	override class var identifier: OCExtensionIdentifier? { OCExtensionIdentifier("com.owncloud.action.manageFileTags") }
	override class var category: ActionCategory? { .normal }
	override class var name: String { HCL10n.TagManage.actionTitle }
	override class var locations: [OCExtensionLocationIdentifier]? {
		[.moreItem, .moreDetailItem, .multiSelection, .contextMenuItem, .tableRow, .accessibilityCustomAction]
	}

	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		guard forContext.items.count == 1,
		      let item = forContext.items.first else {
			return .none
		}
		guard item.type == .file, !item.isPlaceholder else { return .none }
		if let fileID = effectiveFileID(for: item),
		   fileID.hasPrefix(String(OCFileIDPlaceholderPrefix)) {
			return .none
		}
		return .nearFirst
	}

	private static func effectiveFileID(for item: OCItem) -> String? {
		if let fileID = item.fileID as String?, !fileID.isEmpty {
			return fileID
		}
		if let fileID = item.location?.fileID as String?, !fileID.isEmpty {
			return fileID
		}
		return nil
	}

	override func run() {
		guard context.items.count == 1,
		      let item = context.items.first,
		      let host = context.viewController,
		      let core,
		      core.connectionStatus == .online,
		      Self.effectiveFileID(for: item) != nil else {
			completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let vc = FileTagsManagementViewController(item: item, core: core)
		vc.navigationItem.title = HCL10n.TagManage.title
		vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: vc, action: #selector(FileTagsManagementViewController.dismissAnimated))

		let nav = ThemeNavigationController(rootViewController: vc)
		nav.sheetPresentationController?.preferredCornerRadius = 28
		if UIDevice.current.userInterfaceIdiom == .pad {
			nav.modalPresentationStyle = .pageSheet
			nav.preferredContentSize = CGSize(width: 704, height: 944)
		}

		host.present(nav, animated: true)
		completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		OCSymbol.icon(forSymbolName: "tag")?.withRenderingMode(.alwaysTemplate)
	}
}
