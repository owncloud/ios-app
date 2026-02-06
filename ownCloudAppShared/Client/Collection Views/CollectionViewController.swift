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

open class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, Themeable, ThemeCSSAutoSelector {
	public var clientContext: ClientContext?

	public var supportsHierarchicContent: Bool
	public var usesStackViewRoot: Bool
	public var useWrappedIdentifiers: Bool

	var highlightItemReference: OCDataItemReference?
	var didHighlightItemReference: Bool = false
	var hideNavigationBar: Bool?

	var compressForKeyboard: Bool

	var emptyCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, CollectionViewController.ItemRef>?

	public init(context inContext: ClientContext?, sections inSections: [CollectionViewSection]?, useStackViewRoot: Bool = false, hierarchic: Bool = false, compressForKeyboard: Bool = false, useWrappedIdentifiers: Bool = false, highlightItemReference: OCDataItemReference? = nil) {
		supportsHierarchicContent = hierarchic
		usesStackViewRoot = useStackViewRoot
		self.useWrappedIdentifiers = hierarchic ? hierarchic : useWrappedIdentifiers
		self.highlightItemReference = highlightItemReference
		self.compressForKeyboard = compressForKeyboard

		super.init(nibName: nil, bundle: nil)

		emptyCellRegistration = UICollectionView.CellRegistration(handler: { cell, indexPath, itemIdentifier in
		})

		inContext?.postInitialize(owner: self)

		clientContext = ClientContext(with: inContext, modifier: { context in
			context.originatingViewController = self
		})

		if let core = clientContext?.core {
			self.navigationItem.title = core.bookmark.shortName
		}

		// Add datasources
		if let addSections = inSections {
			add(sections: addSections)
		}
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if _themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	// MARK: - View configuration
	public func configureViews() {
		createCollectionView()

		if usesStackViewRoot {
			createStackView()
		}

		configureLayout()
	}

	public func configureLayout() {
		collectionView.translatesAutoresizingMaskIntoConstraints = false

		if usesStackViewRoot, let stackView = stackView {
			let safeAreaView = ThemeCSSView(frame: view.bounds)
			safeAreaView.translatesAutoresizingMaskIntoConstraints = false
			safeAreaView.embed(toFillWith: collectionView.withScreenshotProtection, enclosingAnchors: safeAreaView.safeAreaAnchorSet)

			stackView.addArrangedSubview(safeAreaView)
		} else {
			view.embed(toFillWith: collectionView.withScreenshotProtection, enclosingAnchors: view.defaultAnchorSet)
		}
	}

	// MARK: - Stack View
	public var stackView : UIStackView?
	public var stackedChildren : [UIViewController] = []

	public func createStackView() {
		if stackView == nil {
			stackView = UIStackView(frame: .zero)
			stackView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			stackView?.axis = .vertical
			stackView?.spacing = 0
			stackView?.distribution = .fill
		}
	}

	public enum StackedPosition : CaseIterable {
		case top
		case bottom
	}

	public func addStacked(child viewController: UIViewController, position: StackedPosition, relativeTo: UIView? = nil) {
		if !usesStackViewRoot {
			Log.error("Adding stacked view controllers requires a stackView root. Initialize with useStackedViewRoot:true.")
			return
		}

		addChild(viewController)

		switch position {
			case .top:
				if let relativeTo = relativeTo, let position = stackView?.arrangedSubviews.firstIndex(of: relativeTo) {
					stackView?.insertArrangedSubview(viewController.view, at: position)
				} else {
					stackView?.insertArrangedSubview(viewController.view, at: 0)
				}

			case .bottom:
				if let relativeTo = relativeTo, let position = stackView?.arrangedSubviews.firstIndex(of: relativeTo) {
					stackView?.insertArrangedSubview(viewController.view, at: position+1)
				} else {
					stackView?.addArrangedSubview(viewController.view)
				}
		}

		stackedChildren.append(viewController)

		viewController.didMove(toParent: self)
	}

	public func removeStacked(child viewController: UIViewController) {
		if !usesStackViewRoot {
			Log.error("Removing stacked view controllers requires a stackView root. Initialize with useStackedViewRoot:true.")
			return
		}

		viewController.willMove(toParent: nil)

		stackedChildren.removeAll(where: { vc in (vc === viewController) })

		viewController.view.removeFromSuperview()
		viewController.removeFromParent()
	}

	// MARK: - Collection View
	var collectionView : UICollectionView! = nil
	var collectionViewDataSource: UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>! = nil

	public override func loadView() {
		super.loadView()

		if usesStackViewRoot {
			createStackView()
			if let stackView {
				view.embed(toFillWith: stackView, enclosingAnchors: compressForKeyboard ? view.safeAreaWithKeyboardAnchorSet : view.safeAreaAnchorSet)
			}
		}
	}

	open override func viewDidLoad() {
		super.viewDidLoad()
		configureViews()
		configureDataSource()
	}

	open func createCollectionViewLayout() -> UICollectionViewLayout {
		let configuration = UICollectionViewCompositionalLayoutConfiguration()

		configuration.interSectionSpacing = 0

		return UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, layoutEnvironment in
			if let self = self {
				let visibleSections = self.sections.filter({ section in
					return !section.hidden
				})

				if sectionIndex >= 0, sectionIndex < visibleSections.count, visibleSections.count > 0 {
					return visibleSections[sectionIndex].provideCollectionLayoutSection(layoutEnvironment: layoutEnvironment)
				}
			}

			// Fallback - will typically only be called if the CollectionViewController has already been deallocated
			// (such as when navigating upwards from the originating view controller during a drag & drop operation)
			return CollectionViewSection.CellLayout.list(appearance: .grouped).collectionLayoutSection(layoutEnvironment: layoutEnvironment)
		}, configuration: configuration)
	}

	open func createCollectionView() {
		if collectionView == nil {
			collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createCollectionViewLayout())
			collectionView.contentInsetAdjustmentBehavior = .never
			collectionView.contentInset = .zero
			collectionView.delegate = self
			collectionView.dragDelegate = self
			collectionView.dropDelegate = self
			collectionView.dragInteractionEnabled = dragInteractionEnabled
		}
	}

	// MARK: - Cover view
	var coverRootView: UIView? {
		willSet {
			coverRootView?.removeFromSuperview()
		}

		didSet {
			if let coverRootView {
				view.embed(toFillWith: coverRootView)
			}
		}
	}

	public enum CoverViewLayout {
		case fill
		case center
		case top
	}

	open func setCoverView(_ coverView: UIView?, layout: CoverViewLayout) {
		if view != nil {
			if let coverView {
				let rootView = UIView()
				rootView.translatesAutoresizingMaskIntoConstraints = false
				rootView.backgroundColor = Theme.shared.activeCollection.css.getColor(.fill, for: collectionView)

				switch layout {
					case .fill:
						rootView.embed(toFillWith: coverView)

					case .center:
						rootView.embed(centered: coverView, enclosingAnchors: rootView.safeAreaAnchorSet)

					case .top:
						rootView.addSubview(coverView)
						NSLayoutConstraint.activate([
							coverView.leadingAnchor.constraint(greaterThanOrEqualTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
							coverView.trailingAnchor.constraint(greaterThanOrEqualTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: 20),
							coverView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
							coverView.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: 20),
							coverView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
						])
				}

				self.coverRootView = rootView
			} else {
				self.coverRootView = nil
			}
		}
	}

	// MARK: - Collection View Datasource
	open func configureDataSource() {
		dataSourceWorkQueue.executor = { (job, completionHandler) in
			job(completionHandler)
		}

		collectionViewDataSource = UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, collectionItemRef: CollectionViewController.ItemRef) -> UICollectionViewCell? in
			if let sectionIdentifier = self?.collectionViewDataSource.sectionIdentifier(for: indexPath.section),
			   let section = self?.sectionsByID[sectionIdentifier] {
				var cell = section.provideReusableCell(for: collectionView, collectionItemRef: collectionItemRef, indexPath: indexPath)

				if let cell {
					return cell
				} else if let self, !self.useWrappedIdentifiers {
					// # UICollectionViewDiffableDataSource quirk workaround:
					// If a cell moves from one section to another, the cell is requeested from the indexPath / section that it was PREVIOUSLY located at/in.
					// At that point, however, the data source for that section no longer contains the item, so no cell can be returned.
					// For this case, all other sections are asked to provide the cell before falling through.

					for otherSection in self.sections {
						if !otherSection.hidden, otherSection != section {
							cell = otherSection.provideReusableCell(for: collectionView, collectionItemRef: collectionItemRef, indexPath: indexPath)

							if let cell {
								return cell
							}
						}
					}
				}
			}

			return self?.provideUnknownCell(for: indexPath, item: collectionItemRef)
		}

		if supportsHierarchicContent {
			collectionViewDataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] (parentItemRef) in
				if let (_, sectionIdentifier) = self?.unwrap(parentItemRef) {
					if let sectionIdentifier = sectionIdentifier,
					   let section = self?.sectionsByID[sectionIdentifier] {
					   	section.addExpanded(item: parentItemRef)
					}
				}
			}
			collectionViewDataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] (parentItemRef) in
				if let (_, sectionIdentifier) = self?.unwrap(parentItemRef) {
					if let sectionIdentifier = sectionIdentifier,
					   let section = self?.sectionsByID[sectionIdentifier] {
					   	section.removeExpanded(item: parentItemRef)
					}
				}
			}
			collectionViewDataSource.sectionSnapshotHandlers.snapshotForExpandingParent = { [weak self] (parentItemRef, sectionSnapshot) in
				if let (_, sectionIdentifier) = self?.unwrap(parentItemRef) {
					if let sectionIdentifier = sectionIdentifier,
					   let collectionView = self?.collectionView,
					   let section = self?.sectionsByID[sectionIdentifier] {
						return section.provideHierarchicContent(for: collectionView, parentItemRef: parentItemRef, existingSectionSnapshot: sectionSnapshot)
					}
				}

				return sectionSnapshot
			}
		}

		collectionViewDataSource.supplementaryViewProvider = { [weak self] (collectionView, elementKind, indexPath) in
			// Fetch by section ID (may fail if section is process of being hidden)
			if let sectionIdentifier = self?.collectionViewDataSource.sectionIdentifier(for: indexPath.section),
			   let section = self?.sectionsByID[sectionIdentifier], !section.hidden,
			   let supplementaryItemProvider = CollectionViewSupplementaryCellProvider.providerFor(elementKind),
			   let supplementaryItem = section.boundarySupplementaryItems?.first(where: { item in
				   return item.elementKind == elementKind
			   }) {
			   	return supplementaryItemProvider.provideCell(for: collectionView, section: section, supplementaryItem: supplementaryItem, indexPath: indexPath)
			}

			// Fetch by section offset
			if let section = self?.section(at: indexPath.section),
			   let supplementaryItemProvider = CollectionViewSupplementaryCellProvider.providerFor(elementKind),
			   let supplementaryItem = section.boundarySupplementaryItems?.first(where: { item in
				   return item.elementKind == elementKind
			   }) {
			   	return supplementaryItemProvider.provideCell(for: collectionView, section: section, supplementaryItem: supplementaryItem, indexPath: indexPath)
			}

			return nil
		}

		// initial data
		updateSource(animatingDifferences: false)
	}

	private var dataSourceWorkQueue = OCAsyncSequentialQueue()

	func performDataSourceUpdate(with block: @escaping (_ updateDone: @escaping () -> Void) -> Void) {
		// Usage of a queue that performs immediately (unless busy) is needed as requesting an update during an update
		// will raise an exception "Deadlock detected: calling this method on the main queue with outstanding async updates is not permitted and will deadlock. Please always submit updates either always on the main queue or always off the main queue" - even though the updates have been performed from the same (main) queue always
		dataSourceWorkQueue.async({ updateDone in
			block(updateDone)
		})
	}

	// MARK: - Sections
	var sections: [CollectionViewSection] = []
	var sectionsByID: [CollectionViewSection.SectionIdentifier : CollectionViewSection] = [:]

	public var allSections: [CollectionViewSection] {
		return sections
	}

	private func isAssociated(section: CollectionViewSection) -> Bool {
		return section.collectionViewController == self
	}

	private func associate(section: CollectionViewSection) {
		section.collectionViewController = self
		sectionsByID[section.identifier] = section
	}

	private func disassociate(section: CollectionViewSection) {
		section.collectionViewController = nil
		sectionsByID[section.identifier] = nil
	}

	open func add(sections sectionsToAdd: [CollectionViewSection]) {
		for section in sectionsToAdd {
			associate(section: section)
			sections.append(section)
		}

		updateSource()
	}

	open func insert(sections sectionsToAdd: [CollectionViewSection], at index: Int) {
		for section in sectionsToAdd {
			associate(section: section)
		}

		sections.insert(contentsOf: sectionsToAdd, at: index)

		updateSource()
	}

	open func remove(sections sectionsToRemove: [CollectionViewSection]) {
		for section in sectionsToRemove {
			disassociate(section: section)

			if let sectionIdx = sections.firstIndex(of: section) {
				sections.remove(at: sectionIdx)
			}
		}

		updateSource()
	}

	// MARK: - Sections Datasource changes
	private var _needsSourceUpdate: Bool = false
	private var _needsSourceUpdateWithAnimation: Bool = false

	open func setNeedsSourceUpdate(animatingDifferences: Bool = true) {
		var needsUpdate: Bool = false

		OCSynchronized(self) {
			if !_needsSourceUpdate {
				_needsSourceUpdate = true
				_needsSourceUpdateWithAnimation = animatingDifferences

				needsUpdate = true
			} else {
				if _needsSourceUpdateWithAnimation && !animatingDifferences {
					_needsSourceUpdateWithAnimation = false
				}
			}
		}

		if needsUpdate {
			OnMainThread {
				var performUpdate: Bool = false
				var animatedUpdate: Bool = false

				OCSynchronized(self) {
					performUpdate = self._needsSourceUpdate
					animatedUpdate = self._needsSourceUpdateWithAnimation

					self._needsSourceUpdate = false
				}

				if performUpdate {
					self.__updateSource(animatingDifferences: animatedUpdate)
				}
			}
		}
	}

	// MARK: - Sections Datasource
	private var _sectionsSubscription: OCDataSourceSubscription?
	open var sectionsDataSource: OCDataSource? {
		willSet {
			_sectionsSubscription?.terminate()
			_sectionsSubscription = nil
		}

		didSet {
			_sectionsSubscription = sectionsDataSource?.subscribe(updateHandler: { [weak self] (subscription) in
				self?.updateSections(from: subscription.snapshotResettingChangeTracking(true))
			}, on: .main, trackDifferences: true, performInitialUpdate: true)
		}
	}

	private func updateSections(from snapshot: OCDataSourceSnapshot) {
		var newSections: [CollectionViewSection] = []

		if let addedItems = snapshot.addedItems {
			for itemRef in addedItems {
				if let itemRecord = try? sectionsDataSource?.record(forItemRef: itemRef), let section = itemRecord.item as? CollectionViewSection {
					associate(section: section)
				}
			}
		}

		if let removedItems = snapshot.removedItems {
			for itemRef in removedItems {
				if let itemRecord = try? sectionsDataSource?.record(forItemRef: itemRef), let section = itemRecord.item as? CollectionViewSection {
					disassociate(section: section)
				}
			}
		}

		for itemRef in snapshot.items {
			if let itemRecord = try? sectionsDataSource?.record(forItemRef: itemRef), let section = itemRecord.item as? CollectionViewSection {
				if !isAssociated(section: section) {
					associate(section: section)
				}
				newSections.append(section)
			}
		}

		sections = newSections

		updateSource()
	}

	open var animateDifferences : Bool = true

	func updateSource(animatingDifferences: Bool = true) {
		setNeedsSourceUpdate(animatingDifferences: animatingDifferences)
	}

	func __updateSource(animatingDifferences: Bool = true) {
		performDataSourceUpdate { updateDone in
			self._updateSource(animatingDifferences: animatingDifferences)
			updateDone()
		}
	}

	func _updateSource(animatingDifferences: Bool = true) {
		guard let collectionViewDataSource = collectionViewDataSource else {
			return
		}

		var snapshot = NSDiffableDataSourceSnapshot<CollectionViewSection.SectionIdentifier, CollectionViewController.ItemRef>()
		var snapshotsBySection = [CollectionViewSection.SectionIdentifier : NSDiffableDataSourceSectionSnapshot<CollectionViewController.ItemRef>]()
		var updatedItems : [CollectionViewController.ItemRef] = []
		var selectedItemRefs: [ItemRef]?

		let updateWithAnimation = animatingDifferences && !useWrappedIdentifiers

		if !updateWithAnimation {
			// Selection is lost when updating without animation (via https://forums.developer.apple.com/forums/thread/656529?answerId=627227022#627227022)
			let selectedIndexPaths = collectionView.indexPathsForSelectedItems
			selectedItemRefs = selectedIndexPaths?.compactMap({ indexPath in
				return collectionViewDataSource.itemIdentifier(for: indexPath)
			})
		}

		// Log.debug("<=========================>")

		for section in sections {
			if !section.hidden {
				snapshot.appendSections([section.identifier])
				if !useWrappedIdentifiers {
					section.populate(snapshot: &snapshot)
				} else {
					snapshotsBySection[section.identifier] = collectionViewDataSource.snapshot(for: section.identifier)
				}
			}
		}

		collectionViewDataSource.apply(snapshot, animatingDifferences: updateWithAnimation)

		if useWrappedIdentifiers {
			for section in sections {
				if !section.hidden {
					let (sectionSnapshot, sectionUpdatedItems) = section.composeSectionSnapshot(from: snapshotsBySection[section.identifier])

					collectionViewDataSource.apply(sectionSnapshot, to: section.identifier, animatingDifferences: false)

					if let sectionUpdatedItems = sectionUpdatedItems {
						updatedItems.append(contentsOf: sectionUpdatedItems)
					}
				}
			}

			if updatedItems.count > 0 {
				var snapshot = collectionViewDataSource.snapshot()
				snapshot.reconfigureItems(updatedItems)
				collectionViewDataSource.apply(snapshot, animatingDifferences: false)
			}
		}

		// Restore selected item refs
		if let selectedItemRefs {
			var selectIndexPaths: [IndexPath]?

			selectIndexPaths = selectedItemRefs.compactMap({ itemRef in
				collectionViewDataSource.indexPath(for: itemRef)
			})

			if let selectIndexPaths, selectIndexPaths.count > 0 {
				OnMainThread {
					for selectedIndexPath in selectIndexPaths {
						self.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredVertically)
					}
				}
			}
		}

		// Notify view controller of content updates
		setContentDidUpdate()
	}

	open func section(at inTargetIndex: Int) -> CollectionViewSection? {
		let targetIndex = collectionView.dataSourceSectionIndex(forPresentationSectionIndex: inTargetIndex)

		if (targetIndex >= 0) && (targetIndex < sections.count) {
			var index : Int = 0

			for section in sections {
				if !section.hidden {
					if index == targetIndex {
						return section
					}

					index += 1
				}
			}
		}

		return nil
	}

	open func index(of findSection: CollectionViewSection) -> Int? {
		var index : Int = 0

		for section in sections {
			if !section.hidden {
				if section == findSection {
					return index
				}

				index += 1
			}
		}

		return nil
	}

	public func updateSections(with block: (_ sections: [CollectionViewSection]) -> Void, animated: Bool) {
		block(sections)
		updateSource(animatingDifferences: animated)
	}

	public func reload(sections: [CollectionViewSection], animated: Bool) {
		let reloadSectionIDs = sections.map({ section in return section.identifier })

		if reloadSectionIDs.count > 0 {
			performDataSourceUpdate { updateDone in
				var snapshot = self.collectionViewDataSource.snapshot()
				let existingSectionIdentifiers = snapshot.sectionIdentifiers
				let applicableSectionIDs = reloadSectionIDs.filter { sectionID in
					return existingSectionIdentifiers.contains(sectionID)
				}

				if applicableSectionIDs.count > 0 {
					snapshot.reloadSections(applicableSectionIDs)

					self.collectionViewDataSource.apply(snapshot, animatingDifferences: animated)

					// Notify view controller of content updates
					self.setContentDidUpdate()
				} else {
					Log.debug("Reload of sections \(reloadSectionIDs as [String]) requested, but only \(existingSectionIdentifiers as [String]) currently exist. Did nothing.")
				}

				updateDone()
			}
		}
	}

	// MARK: - Client Contexts
	open func clientContext(for indexPath: IndexPath?) -> ClientContext? {
		var sectionClientContext: ClientContext?

		if let indexPath, let section = section(at: indexPath.section) {
			sectionClientContext = section.clientContext
		}

		return sectionClientContext ?? clientContext
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

		public override var description: String {
			return "<WrappedItem: \(sectionIdentifier) : \(dataItemReference)>"
		}
	}

	public func wrap(references: [OCDataItemReference], forSection: CollectionViewSection.SectionIdentifier) -> [ItemRef] {
		if useWrappedIdentifiers {
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
		if useWrappedIdentifiers, let wrappedItem = collectionItemRef as? WrappedItem {
			// unwrap bundled item references + section ID
			return (wrappedItem.dataItemReference, wrappedItem.sectionIdentifier)
		}

		return (collectionItemRef, nil)
	}

	public func retrieveItem(at indexPath: IndexPath, synchronous: Bool = false, action: @escaping ((_ record: OCDataItemRecord, _ indexPath: IndexPath, _ section: CollectionViewSection) -> Void), handleError: ((_ error: Error?) -> Void)? = nil) {
		guard let collectionItemRef = collectionViewDataSource.itemIdentifier(for: indexPath) else {
			handleError?(nil)
			return
		}

		if let sectionIdentifier = collectionViewDataSource.sectionIdentifier(for: indexPath.section),
		   let section = sectionsByID[sectionIdentifier],
		   let dataSource = section.contentDataSource {
		   	let (itemRef, _) = unwrap(collectionItemRef)

		   	if synchronous {
		   		do {
					let record = try dataSource.record(forItemRef: itemRef)
					action(record, indexPath, section)
				} catch {
					handleError?(error)
				}
			} else {
				dataSource.retrieveItem(forRef: itemRef, reusing: nil, completionHandler: { (error, record) in
					guard let record = record else {
						handleError?(error)
						return
					}

					action(record, indexPath, section)
				})
			}
		} else {
			handleError?(nil)
		}
	}

	public func retrieveItems(at indexPaths: [IndexPath], action: @escaping ((_ recordsByIndexPath: [IndexPath : OCDataItemRecord]) -> Void), handleError: ((_ error: Error?) -> Void)? = nil) {
		var recordsByIndexPath : [IndexPath : OCDataItemRecord] = [:]

		for indexPath in indexPaths {
			retrieveItem(at: indexPath, synchronous: true, action: { record, indexPath, _ in
				recordsByIndexPath[indexPath] = record
			}, handleError: handleError)
		}

		action(recordsByIndexPath)
	}

	public func retrieveIndexPaths(for items: [CollectionViewController.ItemRef]) -> [IndexPath] {
		var indexPaths: [IndexPath] = []

		for item in items {
			if let indexPath = collectionViewDataSource.indexPath(for: item) {
				indexPaths.append(indexPath)
			}
		}

		return indexPaths
	}

	// MARK: - Expand / Collapse
//	public func expandCollapse(_ collectionViewItemRef: CollectionViewController.ItemRef) {
//		let (_, sectionID) = unwrap(collectionViewItemRef)
//
//		if let sectionID = sectionID {
//			var snap = collectionViewDataSource.snapshot(for: sectionID)
//			if snap.isExpanded(collectionViewItemRef) {
//				snap.collapse([collectionViewItemRef])
//			} else {
//			    snap.expand([collectionViewItemRef])
//			}
//			collectionViewDataSource.apply(snap, to: sectionID)
//		}
//	}

	// MARK: - Actions
	var actions: [CollectionViewAction] = []
	public func addActions(_ addedActions: [CollectionViewAction]) {
		self.actions.append(contentsOf: addedActions)

		OnMainThread {
			self.runActions()
		}
	}

	private func runActions() {
		var remainingActions: [CollectionViewAction] = []

		for action in self.actions {
			if !action.apply(on: self, completion: nil) {
				remainingActions.append(action)
			}
		}

		self.actions = remainingActions
	}

	// MARK: - Content update
	private var contentDidUpdate: Bool = false
	public func setContentDidUpdate() {
		contentDidUpdate = true
		OnMainThread {
			if self.contentDidUpdate {
				self.contentDidUpdate = false
				self.handleContentUpdate()
			}
		}
	}

	private func handleContentUpdate() {
		runActions()
	}

	// MARK: - Selection
//	var selectedItemReferences: [ItemRef]?
//
//	enum SelectionOperation {
//		case add
//		case replace
//		case toggle
//		case remove
//		case clear
//	}
//
//	func recordSelection(ofItemWith itemRef: ItemRef?, operation: SelectionOperation = .replace) {
//		var effectiveOperation: SelectionOperation = operation
//
//		if operation == .toggle, let itemRef {
//			effectiveOperation = selectedItemReferences?.contains(itemRef) == true ? .remove :. add
//		}
//
//		switch effectiveOperation {
//			case .add:
//				if let itemRef {
//					if selectedItemReferences != nil {
//						selectedItemReferences?.append(itemRef)
//					} else {
//						selectedItemReferences = [ itemRef ]
//					}
//				}
//
//			case .replace:
//				if let itemRef {
//					selectedItemReferences = [ itemRef ]
//				}
//
//			case .remove:
//				if let itemRef {
//					selectedItemReferences = selectedItemReferences?.filter({ checkItemRef in
//						return checkItemRef != itemRef
//					})
//				}
//
//			case .clear:
//				selectedItemReferences = nil
//
//			default: break
//		}
//	}
//
//	func recordSelection(ofItemAt indexPath: IndexPath, operation: SelectionOperation = .replace) {
//		recordSelection(ofItemWith: collectionViewDataSource?.itemIdentifier(for: indexPath), operation: operation)
//	}

	// MARK: - Collection View Delegate
	public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		var shouldSelect : Bool = false
		let interaction : ClientItemInteraction = collectionView.isEditing ? .multiselection : .selection

		retrieveItem(at: indexPath, synchronous: true, action: { [weak self] record, indexPath, section in
			// Return early if .selection is not allowed
			let clientContext = section.clientContext ?? self?.clientContext

			if clientContext?.validate(interaction: interaction, for: record, in: self) != false {
				shouldSelect = true
				if let clientContext, let self {
					shouldSelect = self.allowSelection(of: record, at: indexPath, clientContext: clientContext)
				}
			}
		})

		return shouldSelect
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let interaction : ClientItemInteraction = collectionView.isEditing ? .multiselection : .selection

		// recordSelection(ofItemAt: indexPath, operation: .add)

		retrieveItem(at: indexPath, action: { [weak self] record, indexPath, section in
			// Return early if .selection is not allowed
			let clientContext = section.clientContext ?? self?.clientContext

			if clientContext?.validate(interaction: interaction, for: record, in: self) != false, let clientContext {
				if interaction == .multiselection {
					self?.handleMultiSelection(of: record, at: indexPath, isSelected: true, clientContext: clientContext)
				} else {
					self?.handleSelection(of: record, at: indexPath, clientContext: clientContext)
				}
			}
		}, handleError: { error in
			if interaction == .selection {
				collectionView.deselectItem(at: indexPath, animated: true)
			}
		})
	}

	public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		let interaction : ClientItemInteraction = collectionView.isEditing ? .multiselection : .selection

		// recordSelection(ofItemAt: indexPath, operation: .remove)

		if interaction != .multiselection {
			return
		}

		retrieveItem(at: indexPath, action: { [weak self] record, indexPath, section in
			// Return early if .selection is not allowed
			let clientContext = section.clientContext ?? self?.clientContext

			if clientContext?.validate(interaction: interaction, for: record, in: self) != false, let clientContext {
				self?.handleMultiSelection(of: record, at: indexPath, isSelected: false, clientContext: clientContext)
			}
		})
	}

	public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		var contextMenuConfiguration : UIContextMenuConfiguration?

		retrieveItem(at: indexPath, synchronous: true, action: { [weak self] record, indexPath, section in
			// Return early if .contextMenu is not allowed
			let clientContext = section.clientContext ?? self?.clientContext

			if clientContext?.validate(interaction: .contextMenu, for: record, in: self) != false, let clientContext {
				contextMenuConfiguration = self?.provideContextMenuConfiguration(for: record, at: indexPath, point: point, clientContext: clientContext)
			}
		}, handleError: { error in
			collectionView.deselectItem(at: indexPath, animated: true)
		})

		return contextMenuConfiguration
	}

	// MARK: - Cell action subclassing points
	@discardableResult public func allowSelection(of record: OCDataItemRecord, at indexPath: IndexPath, clientContext: ClientContext) -> Bool {
		if let selectionInteraction = record.item as? DataItemSelectionInteraction {
			if selectionInteraction.allowSelection?(in: self, section: section(at: indexPath.section), with: clientContext) == false {
				return false
			}
		}

		return true
	}

	@discardableResult public func handleSelection(of record: OCDataItemRecord, at indexPath: IndexPath, clientContext: ClientContext) -> Bool {
		// Use item's DataItemSelectionInteraction
		if let selectionInteraction = record.item as? DataItemSelectionInteraction {
			// Try selection first
			if selectionInteraction.handleSelection?(in: self, with: clientContext, completion: { [weak self] (success, forceDeselection) in
				if self?.shouldDeselect(record: record, at: indexPath, afterInteraction: .selection, clientContext: clientContext) == true || forceDeselection {
					self?.collectionView.deselectItem(at: indexPath, animated: true)
				}
			}) == true {
				return true
			}

			// Then try opening
			if selectionInteraction.openItem?(from: self, with: clientContext, animated: true, pushViewController: true, completion: { [weak self] success in
				if self?.shouldDeselect(record: record, at: indexPath, afterInteraction: .selection, clientContext: clientContext) == true {
					self?.collectionView.deselectItem(at: indexPath, animated: true)
				}
			}) != nil {
				return true
			}
		}

		return false
	}

	public func shouldDeselect(record: OCDataItemRecord, at indexPath: IndexPath, afterInteraction: ClientItemInteraction, clientContext: ClientContext) -> Bool {
		return true
	}

	@discardableResult public func handleMultiSelection(of record: OCDataItemRecord, at indexPath: IndexPath, isSelected: Bool, clientContext: ClientContext) -> Bool {
		return false
	}

	@discardableResult public func provideContextMenuConfiguration(for record: OCDataItemRecord, at indexPath: IndexPath, point: CGPoint, clientContext: ClientContext) -> UIContextMenuConfiguration? {
		// Use context.contextMenuProvider
		if let item = record.item, let contextMenuProvider = clientContext.contextMenuProvider {
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

				if let menuItems = contextMenuInteraction.composeContextMenuItems(in: self, location: .contextMenuItem, with: clientContext) {
					return UIMenu(title: "", children: menuItems)
				}

				return nil
			})
		}

		return nil
	}

	// MARK: - Highlighting
	public func highlight(itemRef: OCDataItemReference, animated: Bool) {
		if let itemIndexPath = collectionViewDataSource.indexPath(for: itemRef) {
			collectionView.scrollToItem(at: itemIndexPath, at: .centeredVertically, animated: animated)
		}
	}

	// MARK: - Actions Bar
	open weak var actionsBarViewControllerSection: CollectionViewSection?
	open var actionsBarViewController: CollectionViewController? {
		willSet {
			if let actionsBarViewController = actionsBarViewController {
				removeStacked(child: actionsBarViewController)
			}
		}

		didSet {
			if let actionsBarViewController = actionsBarViewController {
				addStacked(child: actionsBarViewController, position: .bottom)
			}
		}
	}

	public func showActionsBar(with datasource: OCDataSource, context: ClientContext? = nil) {
		if actionsBarViewController == nil {
			let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(48), heightDimension: .fractionalHeight(1))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			let actionSection = CollectionViewSection(identifier: "actions", dataSource: datasource, cellStyle: .init(with: .gridCell), cellLayout: .sideways(item: item, groupSize: itemSize, edgeSpacing: NSCollectionLayoutEdgeSpacing(leading: .fixed(10), top: .fixed(0), trailing: .fixed(10), bottom: .fixed(0)), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0), orthogonalScrollingBehaviour: .continuous), clientContext: clientContext)
			actionSection.animateDifferences = false
			let actionsViewController = CollectionViewController(context: context, sections: [
				actionSection
			])
			actionsBarViewControllerSection = actionSection

			actionsViewController.view.translatesAutoresizingMaskIntoConstraints = false
			actionsViewController.view.heightAnchor.constraint(equalToConstant: 72).isActive = true
			(actionsViewController.view as? UICollectionView)?.showsVerticalScrollIndicator = false
			(actionsViewController.view as? UICollectionView)?.alwaysBounceVertical = false
			(actionsViewController.view as? UICollectionView)?.isScrollEnabled = false

			actionsBarViewController = actionsViewController
		}
	}

	public func closeActionsBar() {
		actionsBarViewController = nil
	}

	// MARK: - Data item target redirection / re-routing
	public func targetedDataItem(for indexPath: IndexPath?, interaction: ClientItemInteraction) -> OCDataItem? {
		var item : OCDataItem?

		if let destinationIndexPath = indexPath {
			// Retrieve item at index path if provided
			retrieveItem(at: destinationIndexPath, synchronous: true, action: { record, indexPath, section in
				let clientContext = section.clientContext ?? self.clientContext

				if clientContext?.validate(interaction: interaction, for: record, in: self) != false {
					item = record.item
				}
			}, handleError: { error in
				Log.debug("Error \(String(describing: error)) retrieving item at destinationIndexPath \(String(describing: destinationIndexPath))")
			})
		} else {
			// Return root item if no index path was provided
			item = clientContext?.rootItem
		}

		return item
	}

	// MARK: - DropTargets variables
	public var dropTargetsDataSource : OCDataSource?

	// MARK: - Drag delegate
	var dragInteractionEnabled: Bool = true {
		didSet {
			// Allows disabling dragging of items, so keyboard control does
			// not include "Drag Item" in the accessibility actions invoked with Tab + Z
			collectionView?.dragInteractionEnabled = dragInteractionEnabled
		}
	}

	public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		if let item = targetedDataItem(for: indexPath, interaction: .drag),
		   let dragInteraction = item as? DataItemDragInteraction {
			if let dragItems = dragInteraction.provideDragItems(with: clientContext) {
				return dragItems
			}
		}

		return []
	}

	public func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
		if let item = targetedDataItem(for: indexPath, interaction: .drag),
		   let dragInteraction = item as? DataItemDragInteraction {
			if let dragItems = dragInteraction.provideDragItems(with: clientContext) {
				return dragItems
			}
		}

		return []
	}

	// MARK: - Drop delegate
	public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		if let dropTargetsProvider = clientContext?.dropTargetsProvider {
			return dropTargetsProvider.canProvideDropTargets(for: session, target: collectionView)
		}

		return true
	}

	public func updateDropTargetsFor(_ collectionView: UICollectionView, dropSession: UIDropSession) {
		if let dropTargetsProvider = clientContext?.dropTargetsProvider {
			let targets = dropTargetsProvider.provideDropTargets(for: dropSession, target: collectionView)

			if let targets = targets, targets.count > 0 {
				if dropTargetsDataSource == nil, actionsBarViewController == nil {
					// Initialize dropTargetsDataSource, but only if actionsBarViewController == nil (=> no existing usage of actions bar)
					let targetsDataSource = OCDataSourceArray()

					targetsDataSource.setVersionedItems(targets)

					dropTargetsDataSource = targetsDataSource
					showActionsBar(with: targetsDataSource, context: ClientContext(with: clientContext, modifier: { context in
						context.dropTargetsProvider = nil
					}))
				} else if let targetsDataSource = dropTargetsDataSource as? OCDataSourceArray {
					// Update existing targets data source
					targetsDataSource.setVersionedItems(targets)
				}
			}
		}
	}

	var lastDropProposalDestinationIndexPath : IndexPath?
	var lastDropProposalDestinationIndexPathValid : Bool = false

	func dropInteraction(for destinationIndexPath: IndexPath?) -> DataItemDropInteraction? {
		var dropInteraction: DataItemDropInteraction?

		if let item = targetedDataItem(for: destinationIndexPath, interaction: .acceptDrop),
		   let itemDropInteraction = item as? DataItemDropInteraction {
		   	dropInteraction = itemDropInteraction
		}

		if let sectionIndex = destinationIndexPath?.section,
		   let section = section(at: sectionIndex),
		   let sectionDropInteraction = section.sectionDropInteraction {
			dropInteraction = sectionDropInteraction
		}

		return dropInteraction
	}

	public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		updateDropTargetsFor(collectionView, dropSession: session)

		Log.debug("Destination index path: \(String(describing: destinationIndexPath))")

		if let dropInteraction = dropInteraction(for: destinationIndexPath),
		   let dropProposal = dropInteraction.allowDropOperation?(for: session, with: clientContext(for: destinationIndexPath)) {
			// Save last requested indexPath because UICollectionViewDropCoordinator.destinationIndexPath will only return the last hit-tested one,
			// so that dropping into a cell-less region of the collection view will have UICollectionViewDropCoordinator.destinationIndexPath return
			// the last hit-tested cell's indexPath - rather than (the accurate) nil
			lastDropProposalDestinationIndexPath = destinationIndexPath
			lastDropProposalDestinationIndexPathValid = true
			return dropProposal
		}

		lastDropProposalDestinationIndexPathValid = false

		return UICollectionViewDropProposal(operation: .forbidden, intent: .unspecified)
	}

	public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
		if let dropInteraction = dropInteraction(for: (lastDropProposalDestinationIndexPathValid ? lastDropProposalDestinationIndexPath : coordinator.destinationIndexPath)) {
			let dragItems = coordinator.items.compactMap { collectionViewDropItem in collectionViewDropItem.dragItem }

			dropInteraction.performDropOperation(of: dragItems, with: clientContext(for: coordinator.destinationIndexPath), handlingCompletion: { didSucceed in
			})
		}
	}

	public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
		if actionsBarViewController == nil {
			updateDropTargetsFor(collectionView, dropSession: session)
		}
	}

	public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
		if let dropTargetsProvider = clientContext?.dropTargetsProvider {
			dropTargetsProvider.cleanupDropTargets?(for: session, target: collectionView)

			if dropTargetsDataSource != nil {
				closeActionsBar()
				dropTargetsDataSource = nil
			}
		}
	}

	// MARK: - Events
	private var _navigationBarWasHidden: Bool?

	var animatedNavigationBarChange: Bool {
		if #available(iOS 26, *) {
			// Workaround: do not animate navigation bar hide/show on iOS 26 to avoid iOS 26 layout bug: https://github.com/owncloud/ios-app/issues/1512
			return false
		}
		return true
	}

	private var _themeRegistered = false
	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if !_themeRegistered {
			_themeRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}

		if let hideNavigationBar, hideNavigationBar, navigationController?.isNavigationBarHidden != hideNavigationBar {
			_navigationBarWasHidden = navigationController?.isNavigationBarHidden
			navigationController?.setNavigationBarHidden(hideNavigationBar, animated: animated && animatedNavigationBarChange)
			if #available(iOS 26, *) {
				// Workaround: do not animate navigation bar hide/show on iOS 26 to avoid iOS 26 layout bug: https://github.com/owncloud/ios-app/issues/1512
				navigationController?.navigationBar.layoutIfNeeded()
			}
		}
	}

	open override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if let _navigationBarWasHidden, navigationController?.isNavigationBarHidden != _navigationBarWasHidden {
			navigationController?.setNavigationBarHidden(_navigationBarWasHidden, animated: animated && animatedNavigationBarChange)
			if #available(iOS 26, *) {
				// Workaround: do not animate navigation bar hide/show on iOS 26 to avoid iOS 26 layout bug: https://github.com/owncloud/ios-app/issues/1512
				navigationController?.navigationBar.layoutIfNeeded()
			}
		}
	}

	// MARK: - Update cell layout
	public func updateCellLayout(animated: Bool = false) {
		collectionView.setCollectionViewLayout(createCollectionViewLayout(), animated: animated)
	}

	// MARK: - Themeing
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if event != .initial {
			updateCellLayout(animated: false)
		}

		overrideUserInterfaceStyle = collection.css.getUserInterfaceStyle()

		collectionView.backgroundColor = collection.css.getColor(.fill, for: collectionView)
		coverRootView?.backgroundColor = collection.css.getColor(.fill, for: collectionView)
		viewIfLoaded?.backgroundColor = collection.css.getColor(.fill, for: collectionView)
	}

	open var cssAutoSelectors: [ThemeCSSSelector] {
		return [.collection]
	}
}

public extension CollectionViewController {
	func relayout(cell: UICollectionViewCell) {
		performDataSourceUpdate { updateDone in
			self.collectionViewDataSource.apply(self.collectionViewDataSource.snapshot(), animatingDifferences: true)

			// Notify view controller of content updates
			self.setContentDidUpdate()

			updateDone()
		}
	}

	func provideUnknownCell(for indexPath: IndexPath, item itemRef: CollectionViewController.ItemRef) -> UICollectionViewCell {
 		if let unknownCellRegistration = emptyCellRegistration {
			let reUseIdentifier : CollectionViewController.ItemRef = NSString(string: "_empty_\(String(describing: itemRef))")
			return collectionView.dequeueConfiguredReusableCell(using: unknownCellRegistration, for: indexPath, item: reUseIdentifier)
		}

		return UICollectionViewCell.emptyFallbackCell
	}
}

public extension UICollectionViewCell {
	static var emptyFallbackCell: UICollectionViewCell {
		return CollectionViewFallbackCell()  // If the code reaches this point, an exception will be returned by UICollectionView*
	}
}

public class CollectionViewFallbackCell : UICollectionViewCell {
	public override var reuseIdentifier: String? {
		return "_emptyFallbackCell"
	}
}
