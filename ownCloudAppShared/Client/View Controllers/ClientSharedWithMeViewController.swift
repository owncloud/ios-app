//
//  ClientSharedWithMeViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.12.22.
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

class ClientSharedWithMeViewController: CollectionViewController {
	var pendingSectionDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var pendingSection: CollectionViewSection?

	var acceptedSectionDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var acceptedSection: CollectionViewSection?

	var declinedSectionDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var declinedSection: CollectionViewSection?

	var noItemsCondition: DataSourceCondition?
	var connectionStatusObservation: NSKeyValueObservation?

	init(context inContext: ClientContext?) {
		super.init(context: inContext, sections: nil, useStackViewRoot: true)
		revoke(in: inContext, when: [ .connectionClosed ])
		navigationItem.titleLabelText = OCLocalizedString("Shared with me", nil)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	observeScreenshotEvent()
	watermark(
			username: self.clientContext?.core?.bookmark.userName,
			userMail: self.clientContext?.core?.bookmark.user?.emailAddress
		)

	override func viewDidLoad() {
		super.viewDidLoad()

		// Disable dragging of items, so keyboard control does
		// not include "Drag Item" in the accessibility actions
		// invoked with Tab + Z
		dragInteractionEnabled = false

		func buildSection(identifier: CollectionViewSection.SectionIdentifier, titled title: String, compositionDataSource: OCDataSourceComposition, contentDataSource: OCDataSource, queryDataSource: OCDataSource? = nil) -> CollectionViewSection {
			var sectionContext = clientContext

			if let queryDataSource, clientContext?.queryDatasource == nil {
				sectionContext = ClientContext(with: sectionContext, modifier: { context in
					context.queryDatasource = queryDataSource
					context.viewControllerPusher = nil
				})
			}

			let section = CollectionViewSection(identifier: identifier, dataSource: contentDataSource, cellStyle: .init(with: .tableCell), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)), clientContext: sectionContext)
			section.hideIfEmptyDataSource = contentDataSource
			section.hidden = true

			section.boundarySupplementaryItems = [
				.title(title, pinned: true)
			]

			return section
		}

		if let pendingDataSource = clientContext?.core?.sharedWithMePendingDataSource,
		   let acceptedDataSource = clientContext?.core?.sharedWithMeAcceptedDataSource,
		   let declinedDataSource = clientContext?.core?.sharedWithMeDeclinedDataSource {
			pendingSection = buildSection(identifier: "pending", titled: OCLocalizedString("Pending", nil), compositionDataSource: pendingSectionDataSource, contentDataSource: pendingDataSource)
			acceptedSection = buildSection(identifier: "accepted", titled: OCLocalizedString("Accepted", nil), compositionDataSource: acceptedSectionDataSource, contentDataSource: acceptedDataSource, queryDataSource: clientContext?.core?.useDrives == true ? acceptedDataSource : nil)
			declinedSection = buildSection(identifier: "declined", titled: OCLocalizedString("Declined", nil), compositionDataSource: declinedSectionDataSource, contentDataSource: declinedDataSource)

			add(sections: [
				pendingSection!,
				acceptedSection!,
				declinedSection!
			])

			noItemsCondition = DataSourceCondition(.allOf([
				DataSourceCondition(.empty, with: pendingDataSource),
				DataSourceCondition(.empty, with: acceptedDataSource),
				DataSourceCondition(.empty, with: declinedDataSource)
			]), initial: true, action: { [weak self] condition in
				self?.updateCoverMessage()
			})
		}

		connectionStatusObservation = clientContext?.core?.observe(\OCCore.connectionStatus, options: .initial, changeHandler: { [weak self] core, change in
			OnMainThread {
				self?.updateCoverMessage()
			}
		})
	}

	func updateCoverMessage() {
		var coverView: UIView?

		if clientContext?.core?.connectionStatus != .online {
			let offlineMessage = ComposedMessageView(elements: [
				.image(OCSymbol.icon(forSymbolName: "network")!, size: CGSize(width: 64, height: 48), alignment: .centered),
				.title(OCLocalizedString("Sharing requires an active connection.", nil), alignment: .centered)
			])

			coverView = offlineMessage
		}

		if coverView == nil, noItemsCondition?.fulfilled == true {
			let noShareMessage = ComposedMessageView(elements: [
				.image(OCSymbol.icon(forSymbolName: "arrowshape.turn.up.left")!, size: CGSize(width: 64, height: 48), alignment: .centered),
				.title(OCLocalizedString("No items shared with you", nil), alignment: .centered)
			])

			coverView = noShareMessage
		}

		setCoverView(coverView, layout: .top)
	}
	
	deinit {
		stopObserveScreenshotEvent()
	}
}
