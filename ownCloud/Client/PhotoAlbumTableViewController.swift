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
import ownCloudAppShared

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
		var thumbnail: UIImage?
		var collection: PHAssetCollection?

		var countString : String {
			if count != nil {
				return "\(count!)"
			} else {
				return ""
			}
		}
	}

	var albums = [PhotoAlbum]()

	var fetchAlbumQueue = DispatchQueue(label: "com.owncloud.photoalbum.queue", qos: DispatchQoS.userInitiated)

	// The queue which is used to fetch thumbnails uses lowest priority, to ensure that scrolling is smooth
	var fetchAlbumThumbnailsQueue = DispatchQueue(label: "com.owncloud.photoalbum.queue", qos: DispatchQoS.background)

	// This is used just to pass the selection callback to PhotoSelectionViewController when an album is selected
	var selectionCallback :PhotosSelectedCallback?

	// MARK: - UIViewController lifecycle

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self)

		self.title = "Albums".localized
		self.tableView.rowHeight = PhotoAlbumTableViewCell.cellHeight
		self.tableView.register(PhotoAlbumTableViewCell.self, forCellReuseIdentifier: PhotoAlbumTableViewCell.identifier)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
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
		cell?.thumbnailImageView.image = album.thumbnail
		cell?.selectionStyle = .default

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

	fileprivate func updateAlbumThumbnails() {
		// We do it on background view since fetchThumbnailAsset() is quite expensive, getThumbnailImage() is quite quick though
		fetchAlbumThumbnailsQueue.async {
			for row in 0..<self.albums.count {
				let album = self.albums[row]
				if let asset = album.collection?.fetchThumbnailAsset() {
					self.getThumbnailImage(from: asset, completion: { (image) in
						album.thumbnail = image
						OnMainThread {
							self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
						}
					})
				}
			}
		}
	}

	fileprivate func fetchAlbums() {

		guard albums.count == 0 else { return }

		func fetchCollections(_ type:PHAssetCollectionType) {
			let collections = PHAssetCollection.fetchAssetCollections(with: type, subtype: .albumRegular, options: nil)
			collections.enumerateObjects { (collection, _, _) in
				//self.addAlbum(from: assetCollection)
				let count = collection.assetCount
				if count > 0 {
					let album = PhotoAlbum()
					album.collection = collection
					album.name = collection.localizedTitle
					album.count = count
					self.albums.append(album)
				}
			}
		}

		fetchAlbumQueue.async {
			// Fetch smart albums
			fetchCollections(.smartAlbum)

			// Fetch user albums / collections
			fetchCollections(.album)

			OnMainThread {
				self.tableView.reloadData()
			}

			self.updateAlbumThumbnails()
		}
	}

	fileprivate func getThumbnailImage(from asset:PHAsset, completion:@escaping (_ image:UIImage?) -> Void) {
		let imageManager = PHImageManager.default()

		// Setup request options
		let options = PHImageRequestOptions()
		options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
		options.isSynchronous = false
		options.isNetworkAccessAllowed = true
		options.resizeMode = .exact
		let cropSideLength : CGFloat = min(CGFloat(asset.pixelWidth), CGFloat(asset.pixelHeight))
		let square = CGRect(x: 0, y: 0, width: cropSideLength, height: cropSideLength)
		let transform = CGAffineTransform(scaleX: 1.0 / CGFloat(asset.pixelWidth), y: 1.0 / CGFloat(asset.pixelHeight))
		let cropRect = square.applying(transform)
		options.normalizedCropRect = cropRect

		// Consider retina scale factor, since target size has to be provided in pixels
		let scale = UIScreen.main.scale
		let thumbnailHeight = PhotoAlbumTableViewCell.thumbnailHeight
		let thumbnailSize = CGSize(width: thumbnailHeight * scale, height: thumbnailHeight * scale)
		imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: options) { (image, _) in
			completion(image)
		}
	}
}
