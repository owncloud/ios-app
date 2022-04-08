//
//  CollectionViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 31.03.22.
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

public class CollectionViewController: UIViewController, UICollectionViewDelegate {

	public weak var core : OCCore?
	public weak var rootViewController: UIViewController?

	public init(core inCore: OCCore, rootViewController inRootViewController: UIViewController, sections inSections: [CollectionViewSection]?) {
		super.init(nibName: nil, bundle: nil)

		core = inCore
		rootViewController = inRootViewController

		self.navigationItem.title = inCore.bookmark.shortName

		// Add datasources
		if let addSections = inSections {
			add(sections: addSections)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Collection View
	var collectionView : UICollectionView! = nil
	var collectionViewDataSource: UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, OCDataItemReference>! = nil

	public override func viewDidLoad() {
		super.viewDidLoad()
		configureViews()
		configureDataSource()
	}

	func createCollectionViewLayout() -> UICollectionViewLayout {
		let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
		return UICollectionViewCompositionalLayout.list(using: config)
	}

	func configureViews() {
		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createCollectionViewLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.addSubview(collectionView)
		collectionView.delegate = self
	}

	// MARK: - Collection View Datasource
	func configureDataSource() {
		collectionViewDataSource = UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, OCDataItemReference>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, itemRef: OCDataItemReference) -> UICollectionViewCell? in
			// let dataSourceSectionIndex = collectionView.dataSourceSectionIndex(forPresentationSectionIndex: indexPath.section) // not sure if needed
			if let sectionIdentifier = self?.collectionViewDataSource.sectionIdentifier(for: indexPath.section),
			   let section = self?.sectionsByID[sectionIdentifier] {
				return section.provideReusableCell(for: collectionView, itemRef: itemRef, indexPath: indexPath)
			}

			return UICollectionViewCell()
		}

		// initial data
		updateSource(animatingDifferences: false)
	}

	var sections : [CollectionViewSection] = []
	var sectionsByID : [CollectionViewSection.SectionIdentifier : CollectionViewSection] = [:]

	// MARK: - Sections
	func add(sections sectionsToAdd: [CollectionViewSection]) {
		for section in sectionsToAdd {
			section.collectionViewController = self

			sections.append(section)
			sectionsByID[section.identifier] = section
		}

		updateSource()
	}

	func remove(sections sectionsToRemove: [CollectionViewSection]) {
		for section in sectionsToRemove {
			section.collectionViewController = nil

			if let sectionIdx = sections.firstIndex(of: section) {
				sections.remove(at: sectionIdx)
				sectionsByID[section.identifier] = nil
			}
		}

		updateSource()
	}

	func updateSource(animatingDifferences: Bool = true) {
		guard let collectionViewDataSource = collectionViewDataSource else {
			return
		}

		var snapshot = NSDiffableDataSourceSnapshot<CollectionViewSection.SectionIdentifier, OCDataItemReference>()

		for section in sections {
			snapshot.appendSections([section.identifier])

			if let datasourceSnapshot = section.dataSourceSubscription?.snapshotResettingChangeTracking(true) {
				snapshot.appendItems(datasourceSnapshot.items, toSection: section.identifier)

				if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0 {
					snapshot.reloadItems(Array(updatedItems))
				}
			}
		}

		collectionViewDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
	}

	// MARK: - Collection View Delegate
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let itemRef = collectionViewDataSource.itemIdentifier(for: indexPath) else {
			collectionView.deselectItem(at: indexPath, animated: true)
			return
		}

		if let sectionIdentifier = collectionViewDataSource.sectionIdentifier(for: indexPath.section),
		   let section = sectionsByID[sectionIdentifier],
		   let dataSource = section.dataSource {
			dataSource.retrieveItem(forRef: itemRef, reusing: nil, completionHandler: { [weak self] (error, record) in
				if let drive = record?.item as? OCDrive {
					if let core = self?.core, let rootViewController = self?.rootViewController {
						let query = OCQuery(for: drive.rootLocation)
						let rootFolderViewController = ClientQueryViewController(core: core, drive: drive, query: query, rootViewController: rootViewController)

						collectionView.deselectItem(at: indexPath, animated: true)

						self?.navigationController?.pushViewController(rootFolderViewController, animated: true)
					}
				}
			})
		}
	}
}
