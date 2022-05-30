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

	public init(context inContext: ClientContext?, sections inSections: [CollectionViewSection]?, hierarchic: Bool = false) {
		supportsHierarchicContent = hierarchic

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

	public override func viewDidLoad() {
		super.viewDidLoad()
		configureViews()
		configureDataSource()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	public func createCollectionViewLayout() -> UICollectionViewLayout {
		let configuration = UICollectionViewCompositionalLayoutConfiguration()

		configuration.interSectionSpacing = 0

		return UICollectionViewCompositionalLayout.init(sectionProvider: { sectionIndex, layoutEnvironment in
			if sectionIndex > 0, sectionIndex < self.sections.count {
				return self.sections[sectionIndex].provideCollectionLayoutSection(layoutEnvironment: layoutEnvironment)
			}

			// Fallback to allow compilation - should never be called
			return CollectionViewSection.CellLayout.list(appearance: .grouped).collectionLayoutSection(layoutEnvironment: layoutEnvironment)
		}, configuration: configuration)
	}

	public func configureViews() {
		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createCollectionViewLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		collectionView.contentInsetAdjustmentBehavior = .never
		collectionView.contentInset = .zero
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
			// Return early if .selection is not allowed
			if self?.clientContext?.validate(permission: .selection, for: record) != false {
				self?.handleSelection(of: record, at: indexPath)
			}
		}, handleError: { error in
			collectionView.deselectItem(at: indexPath, animated: true)
		})
	}

	public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		var contextMenuConfiguration : UIContextMenuConfiguration?

		retrieveItem(at: indexPath, synchronous: true, action: { [weak self] record, indexPath in
			// Return early if .contextMenu is not allowed
			if self?.clientContext?.validate(permission: .contextMenu, for: record) != false {
				contextMenuConfiguration = self?.provideContextMenuConfiguration(for: record, at: indexPath, point: point)
			}
		}, handleError: { error in
			collectionView.deselectItem(at: indexPath, animated: true)
		})

		return contextMenuConfiguration
	}

	// MARK: - Cell action subclassing points
	@discardableResult public func handleSelection(of record: OCDataItemRecord, at indexPath: IndexPath) -> Bool {
		// Use item's DataItemSelectionInteraction
		if let selectionInteraction = record.item as? DataItemSelectionInteraction {
			// Try selection first
			if selectionInteraction.handleSelection?(in: self, with: clientContext, completion: { [weak self] success in
				self?.collectionView.deselectItem(at: indexPath, animated: true)
			}) == true {
				return true
			}

			// Then try opening
			if selectionInteraction.openItem?(in: self, with: clientContext, animated: true, pushViewController: true, completion: { [weak self] success in
				self?.collectionView.deselectItem(at: indexPath, animated: true)
			}) != nil {
				return true
			}
		}

		return false
	}

	@discardableResult public func provideContextMenuConfiguration(for record: OCDataItemRecord, at indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		// Use context.contextMenuProvider
		if let item = record.item, let clientContext = clientContext, let contextMenuProvider = clientContext.contextMenuProvider {
			return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] _ in
				guard let self = self else {
					return nil
				}

				if let menuItems = contextMenuProvider.composeContextMenuElements(for: self, item: item, location: .contextMenuItem, context: clientContext, sender: nil) {
					return UIMenu(title: "", children: menuItems)
				}

				return nil
			})
		}

		// Use item's DataItemContextMenuInteraction
		if let contextMenuInteraction = record.item as? DataItemContextMenuInteraction {
			return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] _ in
				guard let self = self else {
					return nil
				}

				if let menuItems = contextMenuInteraction.composeContextMenuItems(in: self, location: .contextMenuItem, with: self.clientContext) {
					return UIMenu(title: "", children: menuItems)
				}

				return nil
			})
		}

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
