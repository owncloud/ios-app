//
//  PhotoAlbumViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import Photos

class PhotoAlbumTableViewController : UITableViewController, Themeable {

	var collections = [PHAssetCollection]()
	var thumbnailFetchQueue = OperationQueue()
	var selectionCallback :PhotosSelectedCallback?

	// MARK: - UIViewController lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		thumbnailFetchQueue.qualityOfService = .background
		self.title = "Albums".localized
		self.tableView.rowHeight = PhotoAlbumTableViewCell.cellHeight
		self.tableView.register(PhotoAlbumTableViewCell.self, forCellReuseIdentifier: PhotoAlbumTableViewCell.identifier)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		Theme.shared.register(client: self)
		fetchAlbums()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		Theme.shared.unregister(client: self)
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
	}

	// MARK: - User triggered actions

	@objc func cancel() {
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - UITableView datasource / delegate

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return collections.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: PhotoAlbumTableViewCell.identifier, for: indexPath) as? PhotoAlbumTableViewCell
		let collection = collections[indexPath.row]
		cell?.collection = collection
		return cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let collection = self.collections[indexPath.row]
		let photoSelectionViewController = PhotoSelectionViewController()
		photoSelectionViewController.assetCollection = collection
		photoSelectionViewController.selectionCallback = self.selectionCallback
		self.navigationController?.pushViewController(photoSelectionViewController, animated: true)
	}

	// MARK: - Asset collections fetching

	fileprivate func fetchAlbums() {

		guard collections.count == 0 else { return }

		func fetchCollections(_ type:PHAssetCollectionType) {
			let collections = PHAssetCollection.fetchAssetCollections(with: type, subtype: .albumRegular, options: nil)
			collections.enumerateObjects { [weak self] (assetCollection, _, _) in
				if assetCollection.estimatedAssetCount > 0 {
					self?.collections.append(assetCollection)
				}
			}
		}

		// Fetch smart albums
		fetchCollections(.smartAlbum)

		// Fetch user albums / collections
		fetchCollections(.album)

		self.tableView.reloadData()
	}
}
