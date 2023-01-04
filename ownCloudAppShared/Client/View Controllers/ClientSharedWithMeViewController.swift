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
	var pendingSubscription: OCDataSourceSubscription?

	var acceptedSectionDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var acceptedSection: CollectionViewSection?
	var acceptedSubscription: OCDataSourceSubscription?

	var declinedSectionDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var declinedSection: CollectionViewSection?
	var declinedSubscription: OCDataSourceSubscription?

	init(context inContext: ClientContext?) {
		super.init(context: inContext, sections: nil, useStackViewRoot: true)
		navigationItem.titleLabelText = "Shared with me".localized
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		pendingSubscription?.terminate()
		acceptedSubscription?.terminate()
		declinedSubscription?.terminate()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		func buildSection(identifier: CollectionViewSection.SectionIdentifier, titled title: String, compositionDataSource: OCDataSourceComposition, contentDataSource: OCDataSource) -> (CollectionViewSection, OCDataSourceSubscription) {
			let headerView = ComposedMessageView(elements: [
				.spacing(10),
				.text(title, style: .system(textStyle: .headline), alignment: .leading, insets: .zero)
			])
			// headerView.elementInsets = .zero

			compositionDataSource.addSources([
				OCDataSourceArray(items: [ headerView ]),
				contentDataSource
			])

			let section = CollectionViewSection(identifier: identifier, dataSource: compositionDataSource, cellStyle: .init(with: .tableCell), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), clientContext: clientContext)
			section.hideIfEmptyDataSource = contentDataSource

			let subscription = contentDataSource.subscribe(updateHandler: { [weak section] subscription in
//				let snapshot = subscription.snapshotResettingChangeTracking(true)
//				let numberOfItems = snapshot.numberOfItems
//
//				OnMainThread {
//					section?.hidden = numberOfItems == 0
//				}
			}, on: .main, trackDifferences: true, performIntialUpdate: true)

			return (section, subscription)
		}

		if let pendingDataSource = clientContext?.core?.sharedWithMePendingDataSource,
		   let acceptedDataSource = clientContext?.core?.sharedWithMeAcceptedDataSource,
		   let declinedDataSource = clientContext?.core?.sharedWithMeDeclinedDataSource {
			(pendingSection, pendingSubscription) = buildSection(identifier: "pending", titled: "Pending".localized, compositionDataSource: pendingSectionDataSource, contentDataSource: pendingDataSource)
			(acceptedSection, acceptedSubscription) = buildSection(identifier: "accepted", titled: "Accepted".localized, compositionDataSource: acceptedSectionDataSource, contentDataSource: acceptedDataSource)
			(declinedSection, declinedSubscription) = buildSection(identifier: "declined", titled: "Declined".localized, compositionDataSource: declinedSectionDataSource, contentDataSource: declinedDataSource)

			add(sections: [
				pendingSection!,
				acceptedSection!,
				declinedSection!
			])
		}
	}
}
