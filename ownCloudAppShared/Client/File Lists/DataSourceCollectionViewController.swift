//
//  DataSourceCollectionViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 31.03.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

private let reuseIdentifier = "Cell"

public class CollectionViewCellProvider: NSObject {
	public typealias CellProvider = (_ collectionView: UICollectionView, _ itemRecord: OCDataItemRecord, _ itemRef: OCDataItemReference, _ indexPath: IndexPath) -> UICollectionViewCell

	var provider : CellProvider
	var dataItemType : OCDataItemType

	public func provideCell(for collectionView: UICollectionView, itemRecord: OCDataItemRecord, itemRef: OCDataItemReference, indexPath: IndexPath) -> UICollectionViewCell {
		return provider(collectionView, itemRecord, itemRef, indexPath)
	}

	public init(for type : OCDataItemType, with cellProvider: @escaping CellProvider) {
		provider = cellProvider
		dataItemType = type

		super.init()
	}
}

public class DataSourceCollectionViewController: UIViewController, UICollectionViewDelegate {
	static var cellProviders : [OCDataItemType:CollectionViewCellProvider] = [:]

	public static func register(cellProvider: CollectionViewCellProvider) {
		cellProviders[cellProvider.dataItemType] = cellProvider
	}

	public static func cellProvider(for itemRecord: OCDataItemRecord) -> CollectionViewCellProvider? {
		return cellProviders[itemRecord.type]
	}

	public static func cellProvider(for itemType: OCDataItemType) -> CollectionViewCellProvider? {
		return cellProviders[itemType]
	}

	public weak var core : OCCore?
	public weak var rootViewController: UIViewController?

	public var dataSource: OCDataSource?
	public var dataSourceSubscription : OCDataSourceSubscription?

	public init(core inCore: OCCore, dataSource inDataSource: OCDataSource?, rootViewController inRootViewController: UIViewController) {
		super.init(nibName: nil, bundle: nil)

		core = inCore
		rootViewController = inRootViewController
		dataSource = inDataSource

		self.navigationItem.title = inCore.bookmark.shortName

		// Register cell providers for .drive and .presentable
		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OCDataItemReference> { [weak self] (cell, indexPath, itemRef) in
			var content = cell.defaultContentConfiguration()

			if let itemRecord = try? self?.dataSource?.record(forItemRef: itemRef) {
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

			cell.contentConfiguration = content
			cell.accessories = [ .disclosureIndicator() ]
		}

		DataSourceCollectionViewController.register(cellProvider: CollectionViewCellProvider(for: .drive, with: { collectionView, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))

		DataSourceCollectionViewController.register(cellProvider: CollectionViewCellProvider(for: .presentable, with: { collectionView, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
		}))
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		dataSourceSubscription?.terminate()
	}

	func handleListUpdates(from subscription: OCDataSourceSubscription) {
		updateFromSubscription(animatingDifferences: true)
	}

	/// Collection View implementation
	enum Section: CaseIterable {
		case spaces
	}

	var collectionView : UICollectionView! = nil
	var collectionViewDataSource: UICollectionViewDiffableDataSource<Section, OCDataItemReference>! = nil

	public override func viewDidLoad() {
		super.viewDidLoad()
		configureHierarchy()
		configureDataSource()

		dataSourceSubscription = dataSource?.subscribe(updateHandler: { [weak self] (subscription) in
			self?.handleListUpdates(from: subscription)
		}, on: .main, trackDifferences: true, performIntialUpdate: true)
	}

	func createLayout() -> UICollectionViewLayout {
		let config = UICollectionLayoutListConfiguration(appearance: .plain)
		return UICollectionViewCompositionalLayout.list(using: config)
	}

	func configureHierarchy() {
		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.addSubview(collectionView)
		collectionView.delegate = self
	}

	func configureDataSource() {
		collectionViewDataSource = UICollectionViewDiffableDataSource<Section, OCDataItemReference>(collectionView: collectionView) { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, itemRef: OCDataItemReference) -> UICollectionViewCell? in
			return self?.provideReusableCell(for: collectionView, itemRef: itemRef, indexPath: indexPath) ?? UICollectionViewCell()
		}

		// initial data
		updateFromSubscription(animatingDifferences: false)
	}

	func provideReusableCell(for collectionView: UICollectionView, itemRef: OCDataItemReference, indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?

		if let itemRecord = try? dataSource?.record(forItemRef: itemRef), let itemRecord = itemRecord {
			var cellProvider = DataSourceCollectionViewController.cellProvider(for: itemRecord)

			if cellProvider == nil {
				cellProvider = DataSourceCollectionViewController.cellProvider(for: .presentable)
			}

			if let cellProvider = cellProvider {
				cell = cellProvider.provideCell(for: collectionView, itemRecord: itemRecord, itemRef: itemRef, indexPath: indexPath)
			}
		}

		return cell ?? UICollectionViewCell()
	}

	func updateFromSubscription(animatingDifferences: Bool = true) {
		if let datasourceSnapshot = dataSourceSubscription?.snapshotResettingChangeTracking(true) {
			var snapshot = NSDiffableDataSourceSnapshot<Section, OCDataItemReference>()
			snapshot.appendSections([.spaces])

			let items = datasourceSnapshot.items

			if items.count > 0 {
				snapshot.appendItems(datasourceSnapshot.items)
			}

			if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0 {
				snapshot.reloadItems(Array(updatedItems))
			}

			collectionViewDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
		}
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let itemRef = self.collectionViewDataSource.itemIdentifier(for: indexPath) else {
		    collectionView.deselectItem(at: indexPath, animated: true)
		    return
		}

		dataSource?.retrieveItem(forRef: itemRef, reusing: nil, completionHandler: { [weak self] (error, record) in
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
