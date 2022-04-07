//
//  CollectionViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 31.03.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

private let reuseIdentifier = "Cell"

public class CollectionViewCellProvider: NSObject {
	public typealias CellProvider = (_ collectionView: UICollectionView, _ cellConfiguration: OCDataItemCellConfiguration?, _ itemRecord: OCDataItemRecord, _ itemRef: OCDataItemReference, _ indexPath: IndexPath) -> UICollectionViewCell

	static var cellProviders : [OCDataItemType:CollectionViewCellProvider] = [:]

	public static func register(_ cellProvider: CollectionViewCellProvider) {
		cellProviders[cellProvider.dataItemType] = cellProvider
	}

	public static func providerFor(_ itemRecord: OCDataItemRecord) -> CollectionViewCellProvider? {
		return cellProviders[itemRecord.type]
	}

	public static func providerFor(_ itemType: OCDataItemType) -> CollectionViewCellProvider? {
		return cellProviders[itemType]
	}

	var provider : CellProvider
	var dataItemType : OCDataItemType

	public func provideCell(for collectionView: UICollectionView, cellConfiguration: OCDataItemCellConfiguration?, itemRecord: OCDataItemRecord, itemRef: OCDataItemReference, indexPath: IndexPath) -> UICollectionViewCell {
		// Save any existing cell configuration
		let previousCellConfiguration = itemRef.ocDataItemCellConfiguration

		// Set cell configuration
		itemRef.ocDataItemCellConfiguration = cellConfiguration

		// Ask provider to provide cell
		let cell = provider(collectionView, cellConfiguration, itemRecord, itemRef, indexPath)

		// Restore previously existing cell configuration
		itemRef.ocDataItemCellConfiguration = previousCellConfiguration

		return cell
	}

	public init(for type : OCDataItemType, with cellProvider: @escaping CellProvider) {
		provider = cellProvider
		dataItemType = type

		super.init()
	}
}

public class CollectionViewSection: NSObject {
	public typealias SectionIdentifier = String

	public var identifier: SectionIdentifier

	public var dataSource: OCDataSource? {
		willSet {
			dataSourceSubscription?.terminate()
			dataSourceSubscription = nil
		}

		didSet {
			updateDatasourceSubscription()
		}
	}
	public var dataSourceSubscription : OCDataSourceSubscription?

	weak public var collectionViewController : CollectionViewController?

	func updateDatasourceSubscription() {
		if let dataSource = dataSource {
			dataSourceSubscription = dataSource.subscribe(updateHandler: { [weak self] (subscription) in
				self?.handleListUpdates(from: subscription)
			}, on: .main, trackDifferences: true, performIntialUpdate: true)
		}
	}

	public init(identifier: SectionIdentifier, dataSource inDataSource: OCDataSource?) {
		self.identifier = identifier
		super.init()

		self.dataSource = inDataSource
		updateDatasourceSubscription() // dataSource.didSet is not called during initialization
	}

	deinit {
		dataSourceSubscription?.terminate()
	}

	func handleListUpdates(from subscription: OCDataSourceSubscription) {
		collectionViewController?.updateSource(animatingDifferences: true)
	}

	func provideReusableCell(for collectionView: UICollectionView, itemRef: OCDataItemReference, indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?

		if let itemRecord = try? dataSource?.record(forItemRef: itemRef), let itemRecord = itemRecord {
			var cellProvider = CollectionViewCellProvider.providerFor(itemRecord)

			if cellProvider == nil {
				cellProvider = CollectionViewCellProvider.providerFor(.presentable)
			}

			if let cellProvider = cellProvider, let dataSource = dataSource {
				let cellConfiguration = OCDataItemCellConfiguration(source: dataSource)

				cellConfiguration.reference = itemRef
				cellConfiguration.record = itemRecord

				cell = cellProvider.provideCell(for: collectionView, cellConfiguration: cellConfiguration, itemRecord: itemRecord, itemRef: itemRef, indexPath: indexPath)
			}
		}

		return cell ?? UICollectionViewCell()
	}
}

public class CollectionViewController: UIViewController, UICollectionViewDelegate {

	public weak var core : OCCore?
	public weak var rootViewController: UIViewController?

	public init(core inCore: OCCore, dataSource inDataSource: OCDataSource?, rootViewController inRootViewController: UIViewController) {
		super.init(nibName: nil, bundle: nil)

		core = inCore
		rootViewController = inRootViewController

		self.navigationItem.title = inCore.bookmark.shortName

		// Register cell providers for .drive and .presentable
		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OCDataItemReference> { [weak self] (cell, indexPath, itemRef) in
			var content = cell.defaultContentConfiguration()

			if let cellConfiguration = itemRef.ocDataItemCellConfiguration {
				if let itemRecord = try? cellConfiguration.source?.record(forItemRef: itemRef) {
					if let item = itemRecord?.item {
						if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
							content.text = presentable.title
							content.secondaryText = presentable.subtitle
						}
					} else {
						// Request reconfiguration of cell
						itemRecord?.retrieveItem(completionHandler: { error, itemRecord in
							self?.collectionViewDataSource.requestReconfigurationOfItems([itemRef])
						})
					}
				}
			}

			cell.contentConfiguration = content
			cell.accessories = [ .disclosureIndicator() ]
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .drive, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .presentable, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))

		// Add demo section
		self.add(section: CollectionViewSection(identifier: "hierarchy", dataSource: inDataSource))
		self.add(section: CollectionViewSection(identifier: "all", dataSource: core!.projectDrivesDataSource))
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/// Collection View implementation
	var collectionView : UICollectionView! = nil
	var collectionViewDataSource: UICollectionViewDiffableDataSource<CollectionViewSection.SectionIdentifier, OCDataItemReference>! = nil

	public override func viewDidLoad() {
		super.viewDidLoad()
		configureHierarchy()
		configureDataSource()
	}

	func createLayout() -> UICollectionViewLayout {
		let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
		return UICollectionViewCompositionalLayout.list(using: config)
	}

	func configureHierarchy() {
		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.addSubview(collectionView)
		collectionView.delegate = self
	}

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

	func add(section: CollectionViewSection) {
		section.collectionViewController = self

		sections.append(section)
		sectionsByID[section.identifier] = section

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

//	func provideReusableCell(for collectionView: UICollectionView, itemRef: OCDataItemReference, indexPath: IndexPath) -> UICollectionViewCell {
//		var cell: UICollectionViewCell?
//
//		if let itemRecord = try? dataSource?.record(forItemRef: itemRef), let itemRecord = itemRecord {
//			var cellProvider = CollectionViewController.cellProvider(for: itemRecord)
//
//			if cellProvider == nil {
//				cellProvider = CollectionViewController.cellProvider(for: .presentable)
//			}
//
//			if let cellProvider = cellProvider {
//				cell = cellProvider.provideCell(for: collectionView, itemRecord: itemRecord, itemRef: itemRef, indexPath: indexPath)
//			}
//		}
//
//		return cell ?? UICollectionViewCell()
//	}
//
//	func updateFromSubscription(animatingDifferences: Bool = true) {
//		if let datasourceSnapshot = dataSourceSubscription?.snapshotResettingChangeTracking(true) {
//			var snapshot = NSDiffableDataSourceSnapshot<Section, OCDataItemReference>()
//			snapshot.appendSections([.spaces])
//
//			let items = datasourceSnapshot.items
//
//			if items.count > 0 {
//				snapshot.appendItems(datasourceSnapshot.items)
//			}
//
//			if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0 {
//				snapshot.reloadItems(Array(updatedItems))
//			}
//
//			collectionViewDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
//		}
//	}
//
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
