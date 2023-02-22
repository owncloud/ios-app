//
//  ClientSharedByMeViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 06.01.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class ClientSharedByMeViewController: CollectionViewController {
	var hasByMeSection: Bool
	var sharedByMeDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var sharedByMeSection: CollectionViewSection?

	var hasByLinkSection: Bool
	var sharedByLinkDataSource: OCDataSourceComposition = OCDataSourceComposition(sources: [])
	var sharedByLinkSection: CollectionViewSection?

	init(context inContext: ClientContext?, byMe: Bool = false, byLink: Bool = false) {
		hasByMeSection = byMe
		hasByLinkSection = byLink
		let context = ClientContext(with: inContext, modifier: { context in
			context.viewControllerPusher = nil
		})
		super.init(context: context, sections: nil, useStackViewRoot: true)
		revoke(in: inContext, when: [ .connectionClosed ])
		navigationItem.titleLabelText = (byMe && !byLink) ? "Shared by me".localized : ((!byMe && byLink) ? "Shared by link".localized : "Shared".localized)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		func buildSection(identifier: CollectionViewSection.SectionIdentifier, titled title: String, compositionDataSource: OCDataSourceComposition, contentDataSource: OCDataSource) -> CollectionViewSection {
			let section = CollectionViewSection(identifier: identifier, dataSource: contentDataSource, cellStyle: .init(with: .tableCell), cellLayout: .list(appearance: .plain, contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)), clientContext: clientContext)
			section.hideIfEmptyDataSource = contentDataSource

			section.boundarySupplementaryItems = [
				.title(title, pinned: true)
			]

			return section
		}

		var sectionsToAdd: [CollectionViewSection] = []

		if hasByMeSection, let byMeDataSource = clientContext?.core?.sharedByMeDataSource {
			sharedByMeSection = buildSection(identifier: "byMe", titled: "Shared by me".localized, compositionDataSource: sharedByMeDataSource, contentDataSource: byMeDataSource)
			sectionsToAdd.append(sharedByMeSection!)
		}

		if hasByLinkSection, let byLinkDataSource = clientContext?.core?.sharedByLinkDataSource {
			sharedByLinkSection = buildSection(identifier: "byLink", titled: "Shared by link".localized, compositionDataSource: sharedByLinkDataSource, contentDataSource: byLinkDataSource)
			sectionsToAdd.append(sharedByLinkSection!)
		}

		add(sections: sectionsToAdd)
	}
}
