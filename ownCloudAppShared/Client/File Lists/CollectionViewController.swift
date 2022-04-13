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

	public weak var core: OCCore?
	public weak var rootViewController: UIViewController?

	public var supportsHierarchicContent: Bool

	public init(core inCore: OCCore?, rootViewController inRootViewController: UIViewController?, sections inSections: [CollectionViewSection]?, hierarchic: Bool = false) {
		supportsHierarchicContent = hierarchic

		super.init(nibName: nil, bundle: nil)

		core = inCore
		rootViewController = inRootViewController

		if let core = inCore {
			self.navigationItem.title = core.bookmark.shortName
		}

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
	var collectionViewDataSource: UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>! = nil

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
		collectionViewDataSource = UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, collectionItemRef: CollectionViewController.ItemRef) -> UICollectionViewCell? in
			if let sectionIdentifier = self?.collectionViewDataSource.sectionIdentifier(for: indexPath.section),
			   let section = self?.sectionsByID[sectionIdentifier] {
				return section.provideReusableCell(for: collectionView, collectionItemRef: collectionItemRef, indexPath: indexPath)
			}

			return UICollectionViewCell()
		}

		// initial data
		updateSource(animatingDifferences: false)
	}

	var sections : [CollectionViewSection] = []
	var sectionsByID : [CollectionViewSection.SectionIdentifier : CollectionViewSection] = [:]

	// MARK: - Sections
	public func add(sections sectionsToAdd: [CollectionViewSection]) {
		for section in sectionsToAdd {
			section.collectionViewController = self

			sections.append(section)
			sectionsByID[section.identifier] = section
		}

		updateSource()
	}

	public func remove(sections sectionsToRemove: [CollectionViewSection]) {
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

		var snapshot = NSDiffableDataSourceSnapshot<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>()

		for section in sections {
			snapshot.appendSections([section.identifier])

			section.populate(snapshot: &snapshot)
		}

		collectionViewDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
	}

	// MARK: - Item references
	public typealias ItemRef = NSObject
	public class WrappedItem : NSObject {
		var dataItemReference: OCDataItemReference
		var sectionIdentifier: CollectionViewSection.SectionIdentifier

		init(reference: OCDataItemReference, forSection: CollectionViewSection.SectionIdentifier) {
			dataItemReference = reference
			sectionIdentifier = forSection
			super.init()
		}

		public override func isEqual(_ object: Any?) -> Bool {
			if let otherObj = object as? WrappedItem,
			   dataItemReference.isEqual(otherObj.dataItemReference),
			   sectionIdentifier == otherObj.sectionIdentifier {
				return true
			}

			return false
		}

		public override var hash: Int {
			return dataItemReference.hash ^ sectionIdentifier.hash
		}
	}

	public func wrap(references: [OCDataItemReference], forSection: CollectionViewSection.SectionIdentifier) -> [ItemRef] {
		if supportsHierarchicContent {
			// wrap references and section ID together into a single object
			var itemRefs : [ItemRef] = []

			for reference in references {
				itemRefs.append(WrappedItem(reference: reference, forSection: forSection))
			}

			return itemRefs
		}

		// no hierarchic content, so can just use data source references as-is
		return references
	}

	public func unwrap(_ collectionItemRef: ItemRef) -> (OCDataItemReference, CollectionViewSection.SectionIdentifier?) {
		if supportsHierarchicContent, let wrappedItem = collectionItemRef as? WrappedItem {
			// unwrap bundled item references + section ID
			return (wrappedItem.dataItemReference, wrappedItem.sectionIdentifier)
		}

		return (collectionItemRef, nil)
	}

	// MARK: - Collection View Delegate
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let collectionItemRef = collectionViewDataSource.itemIdentifier(for: indexPath) else {
			collectionView.deselectItem(at: indexPath, animated: true)
			return
		}

		if let sectionIdentifier = collectionViewDataSource.sectionIdentifier(for: indexPath.section),
		   let section = sectionsByID[sectionIdentifier],
		   let dataSource = section.dataSource {
		   	let (itemRef, _) = unwrap(collectionItemRef)

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
