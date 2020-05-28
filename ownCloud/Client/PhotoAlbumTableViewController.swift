//
//  PhotoAlbumViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import Photos

extension PHAssetCollection {
	var assetCount: Int {
		// Some collections can't return the estimated count, therefore we have to fetch the actual assets to get the count
		if self.estimatedAssetCount != NSNotFound {
			return self.estimatedAssetCount
		} else {
			let options = PHFetchOptions()
			options.predicate = NSPredicate(format:  "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
			return PHAsset.fetchAssets(in: self, options: options).count
		}
	}

	func fetchThumbnailAsset() -> PHAsset? {
		// Fetch only one / most recent asset which shall represent the collection as a thumbnail
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		fetchOptions.fetchLimit = 1
		let fetchResult = PHAsset.fetchAssets(in: self, options: fetchOptions)
		return fetchResult.firstObject
	}
}

class PhotoAlbumTableViewController : UITableViewController, Themeable {

	class PhotoAlbum {
		var name: String?
		var count: Int?
		var collection: PHAssetCollection?
		var thumbnailAsset: PHAsset?
		var subtype: PHAssetCollectionSubtype = .albumRegular

		var countString : String {
			if count != nil {
				return "\(count!)"
			} else {
				return ""
			}
		}
	}

	var albums = [PhotoAlbum]()

	// This is used just to pass the selection callback to PhotoSelectionViewController when an album is selected
	var selectionCallback: PhotosSelectedCallback?

	private let activityIndicatorView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)

	// MARK: - UIViewController lifecycle

	deinit {
		Theme.shared.unregister(client: self)
		PhotoAlbumTableViewCell.stopCachingThumbnails()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self)

		self.title = "Albums".localized
		self.tableView.rowHeight = PhotoAlbumTableViewCell.cellHeight
		self.tableView.register(PhotoAlbumTableViewCell.self, forCellReuseIdentifier: PhotoAlbumTableViewCell.identifier)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

		activityIndicatorView.hidesWhenStopped = true
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		fetchAlbums()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
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
		return albums.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: PhotoAlbumTableViewCell.identifier, for: indexPath) as? PhotoAlbumTableViewCell
		let album = albums[indexPath.row]
		cell?.titleLabel.text = album.name
		cell?.countLabel.text = album.countString
		cell?.selectionStyle = .default
		cell?.thumbnailAsset = album.thumbnailAsset

		return cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let album = self.albums[indexPath.row]
		let photoSelectionViewController = PhotoSelectionViewController()
		photoSelectionViewController.assetCollection = album.collection
		photoSelectionViewController.selectionCallback = self.selectionCallback
		self.navigationController?.pushViewController(photoSelectionViewController, animated: true)
	}

	// MARK: - Asset collections fetching

	fileprivate func fetchAlbums() {

		guard albums.count == 0 else { return }

		func fetchCollections(_ type:PHAssetCollectionType, _ albumSubtype:PHAssetCollectionSubtype = .albumRegular) {

			var tempAlbums = [PhotoAlbum]()

			let collections = PHAssetCollection.fetchAssetCollections(with: type, subtype: albumSubtype, options: nil)
			collections.enumerateObjects { (collection, _, _) in
				//self.addAlbum(from: assetCollection)
				let count = collection.assetCount
				if count > 0 {
					let album = PhotoAlbum()
					album.collection = collection
					album.name = collection.localizedTitle
					album.count = count
					album.thumbnailAsset = album.collection?.fetchThumbnailAsset()
					album.subtype = collection.assetCollectionSubtype
					tempAlbums.append(album)
				}
			}

			// Make sure that camera roll is shown first among smart albums
			if type == .smartAlbum {
				tempAlbums.sort { (album1, _) -> Bool in
					return album1.subtype == .smartAlbumUserLibrary
				}
			}

			OnMainThread {
				for album in tempAlbums {
					self.albums.append(album)
					let indexPath = IndexPath(row: (self.albums.count - 1), section: 0)
					self.tableView.insertRows(at: [indexPath], with: .automatic)
				}
			}
		}

		activityIndicatorView.startAnimating()

		DispatchQueue.global(qos: .utility).async {
			// Fetch smart albums
			fetchCollections(.smartAlbum)

			// Fetch user albums / collections
			fetchCollections(.album)

			// Fetch cloud albums
			fetchCollections(.album, .albumCloudShared)

			fetchCollections(.album, .albumMyPhotoStream)

			OnMainThread {
				self.activityIndicatorView.stopAnimating()
			}
		}
	}
}
