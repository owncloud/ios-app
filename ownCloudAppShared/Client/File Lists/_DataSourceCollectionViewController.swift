//
//  DataSourceCollectionViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.04.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

//private let reuseIdentifier = "Cell"
//
//extension OCDataItem {
//
//}

//public class DataSourceSectionSnapshotProvider: NSObject {
//	public var dataSource : OCDataSource
//	public var subscription : OCDataSourceSubscription?
//
//	private var changeCountByItemRef : NSCountedSet
//
//	required init(datasource: OCDataSource) {
//		self.dataSource = datasource
//
//		changeCountByItemRef = NSCountedSet()
//
//		super.init()
//
//		subscription = dataSource.subscribe(updateHandler: { [weak self] (subscription) in
//			self?.handleUpdates()
//		}, on: .main, trackDifferences: true, performIntialUpdate: true)
//	}
//
//	deinit {
//		subscription?.terminate()
//	}
//
//	func handleUpdates() {
//	}
//
//	func generateSectionSnapshot() -> NSDiffableDataSourceSectionSnapshot<OCDataItemReference> {
//		if let subscription = subscription {
//			let dataSnapshot = subscription.snapshotResettingChangeTracking(true)
//
//			var items = dataSnapshot.items
//
//			if let updatedItems = dataSnapshot.updatedItems {
//				changeCountByItemRef.addingObjects(from: updatedItems)
//			}
//		}
//
//		var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<OCDataItemReference>()
//
//		sectionSnapshot.append(dataSnapshot.items)
//		sectionSnapshot.
//
//		reloadItems(Array(dataSnapshot.updatedItems))
//	}
//}
//
//public class DataSourceCollectionViewController: UIViewController, UICollectionViewDelegate {
//	public weak var core : OCCore?
//	public weak var rootViewController: UIViewController?
//
//	public var driveListSubscription : OCDataSourceSubscription?
//
//	public init(core inCore: OCCore, rootViewController inRootViewController: UIViewController) {
//		super.init(nibName: nil, bundle: nil)
//
//		core = inCore
//		rootViewController = inRootViewController
//
//		self.navigationItem.title = inCore.bookmark.shortName
//
//		driveListSubscription = core?.drivesDataSource.subscribe(updateHandler: { [weak self] (subscription) in
//			self?.handleListUpdates(from: subscription)
//		}, on: .main, trackDifferences: true, performIntialUpdate: true)
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//
//	deinit {
//		driveListSubscription?.terminate()
//	}
//
//	func handleListUpdates(from subscription: OCDataSourceSubscription) {
//		updateFromSubscription(animatingDifferences: true)
//	}
//
//	/// Collection View implementation
//	enum Section: CaseIterable {
//		case spaces
//	}
//
//	var collectionView : UICollectionView! = nil
//	var dataSource: UICollectionViewDiffableDataSource<Section, NSObject>! = nil
//
//	public override func viewDidLoad() {
//		super.viewDidLoad()
//		configureHierarchy()
//		configureDataSource()
//	}
//
//	func createLayout() -> UICollectionViewLayout {
//		let config = UICollectionLayoutListConfiguration(appearance: .plain)
//		return UICollectionViewCompositionalLayout.list(using: config)
//	}
//
//	func configureHierarchy() {
//		collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
//		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//		view.addSubview(collectionView)
//		collectionView.delegate = self
//	}
//
//	func configureDataSource() {
////		let cellRegistration = UICollectionView.CellRegistration<CustomListCell, Item> { (cell, indexPath, item) in
////			cell.updateWithItem(item)
////			cell.accessories = [.disclosureIndicator()]
////		}
//
//		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NSObject> { [weak self] (cell, indexPath, itemRef) in
//			var content = cell.defaultContentConfiguration()
//
//			if let itemRecord = try? self?.driveListSubscription?.source?.record(forItemRef: itemRef) {
//				if let item = itemRecord?.item {
//					if let presentable = OCDataRenderer.default.renderItem(item, asType: .presentable, error: nil, withOptions: nil) as? OCDataItemPresentable {
//						content.text = presentable.title
//						content.secondaryText = presentable.subtitle
//					}
//				} else {
//					// Request reconfiguration of cell
//					itemRecord?.retrieveItem(completionHandler: { error, itemRecord in
//						self?.dataSource.requestReconfigurationOfItems([itemRef])
//					})
//				}
//			}
//
//			cell.contentConfiguration = content
//			cell.accessories = [ .disclosureIndicator() ]
//		}
//
//		dataSource = UICollectionViewDiffableDataSource<Section, NSObject>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, itemRef: NSObject) -> UICollectionViewCell? in
//			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemRef)
//		}
//
//		// initial data
//		updateFromSubscription(animatingDifferences: false)
//	}
//
//	func updateFromSubscription(animatingDifferences: Bool = true) {
//		if let datasourceSnapshot = driveListSubscription?.snapshotResettingChangeTracking(true) {
//			var snapshot = NSDiffableDataSourceSnapshot<Section, NSObject>()
//			snapshot.appendSections([.spaces])
//
//			snapshot.appendItems(datasourceSnapshot.items)
//
//			if let updatedItems = datasourceSnapshot.updatedItems, updatedItems.count > 0 {
//				snapshot.reloadItems(Array(updatedItems))
//			}
//
//			dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
//		}
//	}
//
//	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//		guard let itemRef = self.dataSource.itemIdentifier(for: indexPath) else {
//		    collectionView.deselectItem(at: indexPath, animated: true)
//		    return
//		}
//
//		driveListSubscription?.source?.retrieveItem(forRef: itemRef, reusing: nil, completionHandler: { [weak self] (error, record) in
//			if let drive = record?.item as? OCDrive {
//				if let core = self?.core, let rootViewController = self?.rootViewController {
//					let query = OCQuery(for: drive.rootLocation)
//					let rootFolderViewController = ClientQueryViewController(core: core, drive: drive, query: query, rootViewController: rootViewController)
//
//					collectionView.deselectItem(at: indexPath, animated: true)
//
//					self?.navigationController?.pushViewController(rootFolderViewController, animated: true)
//				}
//			}
//		})
//	}
//}
