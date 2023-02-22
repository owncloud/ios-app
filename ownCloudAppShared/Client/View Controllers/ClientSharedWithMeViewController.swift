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

	init(context inContext: ClientContext?) {
		super.init(context: inContext, sections: nil, useStackViewRoot: true)
		revoke(in: inContext, when: [ .connectionClosed ])
		navigationItem.titleLabelText = "Shared with me".localized
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

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

			section.boundarySupplementaryItems = [
				.title(title, pinned: true)
			]

			return section
		}

		if let pendingDataSource = clientContext?.core?.sharedWithMePendingDataSource,
		   let acceptedDataSource = clientContext?.core?.sharedWithMeAcceptedDataSource,
		   let declinedDataSource = clientContext?.core?.sharedWithMeDeclinedDataSource {
			pendingSection = buildSection(identifier: "pending", titled: "Pending".localized, compositionDataSource: pendingSectionDataSource, contentDataSource: pendingDataSource)
			acceptedSection = buildSection(identifier: "accepted", titled: "Accepted".localized, compositionDataSource: acceptedSectionDataSource, contentDataSource: acceptedDataSource, queryDataSource: clientContext?.core?.useDrives == true ? acceptedDataSource : nil)
			declinedSection = buildSection(identifier: "declined", titled: "Declined".localized, compositionDataSource: declinedSectionDataSource, contentDataSource: declinedDataSource)

			add(sections: [
				pendingSection!,
				acceptedSection!,
				declinedSection!
			])
		}
	}
}
