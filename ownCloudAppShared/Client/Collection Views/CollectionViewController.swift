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
import ownCloudApp
import ownCloudSDK

public class CollectionViewController: UIViewController, UICollectionViewDelegate, Themeable {
	public var clientContext: ClientContext?

	public var supportsHierarchicContent: Bool

	public init(context inContext: ClientContext?, sections inSections: [CollectionViewSection]?, hierarchic: Bool = false, listAppearance inListAppearance: UICollectionLayoutListConfiguration.Appearance = .insetGrouped) {
		supportsHierarchicContent = hierarchic
		listAppearance = inListAppearance

		super.init(nibName: nil, bundle: nil)

		inContext?.postInitialize(owner: self)

		clientContext = inContext

		if let core = clientContext?.core {
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

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Collection View
	var collectionView : UICollectionView! = nil
	var collectionViewDataSource: UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>! = nil

	public var listAppearance : UICollectionLayoutListConfiguration.Appearance

	public override func viewDidLoad() {
		super.viewDidLoad()
		configureViews()
		configureDataSource()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	public func createCollectionViewLayout() -> UICollectionViewLayout {
		var config = UICollectionLayoutListConfiguration(appearance: listAppearance)
		switch listAppearance {
			case .plain:
				config.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor

			case .grouped, .insetGrouped:
				config.backgroundColor = Theme.shared.activeCollection.tableGroupBackgroundColor

			default: break
		}
		return UICollectionViewCompositionalLayout.list(using: config)
	}

	public func configureViews() {
		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createCollectionViewLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.addSubview(collectionView)
		collectionView.delegate = self
	}

	// MARK: - Collection View Datasource
	public func configureDataSource() {
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

	public func retrieveItem(at indexPath: IndexPath, synchronous: Bool = false, action: @escaping ((_ record: OCDataItemRecord, _ indexPath: IndexPath) -> Void), handleError: ((_ error: Error?) -> Void)? = nil) {
		guard let collectionItemRef = collectionViewDataSource.itemIdentifier(for: indexPath) else {
			handleError?(nil)
			return
		}

		if let sectionIdentifier = collectionViewDataSource.sectionIdentifier(for: indexPath.section),
		   let section = sectionsByID[sectionIdentifier],
		   let dataSource = section.dataSource {
		   	let (itemRef, _) = unwrap(collectionItemRef)

		   	if synchronous {
		   		do {
					let record = try dataSource.record(forItemRef: itemRef)
					action(record, indexPath)
				} catch {
					handleError?(error)
				}
			} else {
				dataSource.retrieveItem(forRef: itemRef, reusing: nil, completionHandler: { (error, record) in
					guard let record = record else {
						handleError?(error)
						return
					}

					action(record, indexPath)
				})
			}
		} else {
			handleError?(nil)
		}
	}

	// MARK: - Collection View Delegate
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		retrieveItem(at: indexPath, action: { [weak self] record, indexPath in
			self?.handleSelection(of: record, at: indexPath)
		}, handleError: { error in
			collectionView.deselectItem(at: indexPath, animated: true)
		})
	}

	public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		var contextMenuConfiguration : UIContextMenuConfiguration?

		retrieveItem(at: indexPath, synchronous: true, action: { [weak self] record, indexPath in
			contextMenuConfiguration = self?.provideContextMenuConfiguration(for: record, at: indexPath, point: point)
		}, handleError: { error in
			collectionView.deselectItem(at: indexPath, animated: true)
		})

		return contextMenuConfiguration
	}

	 @discardableResult public func handleSelection(of record: OCDataItemRecord, at indexPath: IndexPath) -> Bool {
		if let drive = record.item as? OCDrive {
			let driveContext = ClientContext(with: clientContext, modifier: { context in
				context.drive = drive
			})
			let query = OCQuery(for: drive.rootLocation)
			DisplaySettings.shared.updateQuery(withDisplaySettings: query)

			let rootFolderViewController = ClientItemViewController(context: driveContext, query: query)

			collectionView.deselectItem(at: indexPath, animated: true)

			self.navigationController?.pushViewController(rootFolderViewController, animated: true)

			return true
		}

		return false
	}

	@discardableResult public func provideContextMenuConfiguration(for record: OCDataItemRecord, at indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		return nil
	}

	// MARK: - Themeing
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if event != .initial {
			collectionView.setCollectionViewLayout(createCollectionViewLayout(), animated: false)
		}
	}
}

public extension CollectionViewController {
	func relayout(cell: UICollectionViewCell) {
//		collectionView.setCollectionViewLayout(collectionView.collectionViewLayout, animated: true, completion: nil)

		collectionViewDataSource.apply(collectionViewDataSource.snapshot(), animatingDifferences: true)

//		collectionView.setNeedsLayout()
//		collectionView.layoutIfNeeded()

//		if let indexPath = collectionView.indexPath(for: cell) {
//			let invalidationContext = UICollectionViewLayoutInvalidationContext()
//			invalidationContext.invalidateItems(at: collectionView.indexPathsForVisibleItems)
//			collectionView.collectionViewLayout.invalidateLayout(with: invalidationContext)
//		}
	}
}
