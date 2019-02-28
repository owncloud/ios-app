//
//  PhotoUploadViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

private extension UICollectionView {
	func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
		let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
		return allLayoutAttributes.map { $0.indexPath }
	}
}

typealias PhotosSelectedCallback = ([PHAsset]) -> Void

class PhotoSelectionViewController: UICollectionViewController, Themeable {

	fileprivate let thumbnailSizeMultiplier: CGFloat = 0.2
	fileprivate let verticalInset: CGFloat = 8.0
	fileprivate let horizontalInset: CGFloat = 4.0
	
	var fetchResult: PHFetchResult<PHAsset>!
	var assetCollection: PHAssetCollection?
	var availableWidth: CGFloat = 0
	var selectionCallback: PhotosSelectedCallback?

	fileprivate let imageManager = PHCachingImageManager()
	fileprivate var thumbnailSize: CGSize!
	fileprivate var previousPreheatRect = CGRect.zero
	fileprivate var thumbnailWidth: CGFloat = 80.0

	fileprivate let layout = UICollectionViewFlowLayout()
	fileprivate lazy var durationFormatter = DateComponentsFormatter()

	init() {
		layout.scrollDirection = .vertical
		layout.sectionInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
		super.init(collectionViewLayout: layout)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("not implemented")
	}

	deinit {
		PHPhotoLibrary.shared().unregisterChangeObserver(self)
	}

	// MARK: UIViewController life cycles

	override func viewDidLoad() {
		super.viewDidLoad()
		self.collectionView.allowsMultipleSelection = true

		// Register collection view cell class
		self.collectionView!.register(PhotoSelectionViewCell.self,
									  forCellWithReuseIdentifier: PhotoSelectionViewCell.identifier)
		thumbnailWidth = floor(self.view.bounds.size.width * thumbnailSizeMultiplier)
		layout.itemSize = CGSize(width: thumbnailWidth, height: thumbnailWidth)

		resetCachedAssets()

		// Register observer to handle photo library changes
		PHPhotoLibrary.shared().register(self)

		// Set title for the navigation bar
		if assetCollection != nil {
			self.title = assetCollection!.localizedTitle
			let fetchOptions = PHFetchOptions()
			fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
			fetchResult = PHAsset.fetchAssets(in: assetCollection!, options: fetchOptions)
		} else {
			self.title = "All Photos".localized
		}

		// If the fetchResult property was not pre-populdated, fetch all photos from the library
		if fetchResult == nil {
			let allPhotosOptions = PHFetchOptions()
			allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
			fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
		}

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

		// Setup the toolbar with Upload button
		let uploadButtonItem = UIBarButtonItem(title: "Upload".localized, style: .done, target: self, action: #selector(upload))
		let flexibleSpaceButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		self.toolbarItems = [flexibleSpaceButtonItem, uploadButtonItem, flexibleSpaceButtonItem]

		// Setup duration formatter
		durationFormatter.unitsStyle = .positional
		durationFormatter.allowedUnits = [.hour, .minute, .second]
		durationFormatter.zeroFormattingBehavior = [.pad]
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		Theme.shared.register(client: self)

		self.navigationController?.isToolbarHidden = false

		// Determine the size of the thumbnails to request from the PHCachingImageManager.
		let scale = UIScreen.main.scale
		if let cellSize = (self.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize {
			thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		Theme.shared.unregister(client: self)
		self.navigationController?.isToolbarHidden = true
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		updateCachedAssets()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		let width = view.bounds.inset(by: view.safeAreaInsets).width

		// Adjust the item size if the available width has changed.
		if availableWidth != width {
			availableWidth = width
			let columnCount = (availableWidth / thumbnailWidth).rounded(.towardZero)
			let itemLength = (availableWidth - columnCount - 1) / columnCount
			(self.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: itemLength, height: itemLength)
		}
	}

	// MARK: - Themeable support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.collectionView!.applyThemeCollection(collection)
	}

	// MARK: - User actions

	@objc func cancel() {
		self.dismiss(animated: true, completion: nil)
	}

	@objc func upload() {
		self.dismiss(animated: true) {
			// Get selected assets and call completion callback
			if self.selectionCallback != nil {
				if let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems {
					let selectedRows = selectedIndexPaths.map({ return $0.row })
					let assets = self.fetchResult.objects(at: IndexSet(selectedRows))
					self.selectionCallback!(assets)
				}
			}
		}
	}

	// MARK: - UICollectionViewDelegate

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return fetchResult.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let asset = fetchResult.object(at: indexPath.item)

		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoSelectionViewCell.identifier, for: indexPath) as? PhotoSelectionViewCell
			else { fatalError("Unexpected cell in collection view") }

		// Add a badge to the cell if the PHAsset represents a Live Photo.
		if asset.mediaSubtypes.contains(.photoLive) {
			cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
		}

		if asset.mediaType == .video {
			cell.videoDurationLabel.text = durationFormatter.string(from: asset.duration)
		}

		// Request an image for the asset from the PHCachingImageManager.
		cell.assetIdentifier = asset.localIdentifier
		imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
			// UIKit may have recycled this cell by the handler's activation time.
			// Set the cell's thumbnail image only if it's still showing the same asset.
			if cell.assetIdentifier == asset.localIdentifier {
				cell.thumbnailImage = image
			}
		})

		return cell
	}

	// MARK: - UIScrollViewDelegate

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		updateCachedAssets()
	}

	// MARK: - Asset Caching

	fileprivate func resetCachedAssets() {
		imageManager.stopCachingImagesForAllAssets()
		previousPreheatRect = .zero
	}

	fileprivate func updateCachedAssets() {
		// Update only if the view is visible.
		guard isViewLoaded && view.window != nil else { return }

		// The window you prepare ahead of time is twice the height of the visible rect.
		let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
		let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

		// Update only if the visible area is significantly different from the last preheated area.
		let delta = abs(preheatRect.midY - previousPreheatRect.midY)
		guard delta > view.bounds.height / 3 else { return }

		// Compute the assets to start and stop caching.
		let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
		let addedAssets = addedRects
			.flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
			.map { indexPath in fetchResult.object(at: indexPath.item) }
		let removedAssets = removedRects
			.flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
			.map { indexPath in fetchResult.object(at: indexPath.item) }

		// Update the assets the PHCachingImageManager is caching.
		imageManager.startCachingImages(for: addedAssets,
										targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
		imageManager.stopCachingImages(for: removedAssets,
									   targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)

		// Store the computed rectangle for future comparison.
		previousPreheatRect = preheatRect
	}

	fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
		if old.intersects(new) {
			var added = [CGRect]()
			if new.maxY > old.maxY {
				added += [CGRect(x: new.origin.x, y: old.maxY,
								 width: new.width, height: new.maxY - old.maxY)]
			}
			if old.minY > new.minY {
				added += [CGRect(x: new.origin.x, y: new.minY,
								 width: new.width, height: old.minY - new.minY)]
			}
			var removed = [CGRect]()
			if new.maxY < old.maxY {
				removed += [CGRect(x: new.origin.x, y: new.maxY,
								   width: new.width, height: old.maxY - new.maxY)]
			}
			if old.minY < new.minY {
				removed += [CGRect(x: new.origin.x, y: old.minY,
								   width: new.width, height: new.minY - old.minY)]
			}
			return (added, removed)
		} else {
			return ([new], [old])
		}
	}

}

// MARK: - PHPhotoLibraryChangeObserver

extension PhotoSelectionViewController: PHPhotoLibraryChangeObserver {
	func photoLibraryDidChange(_ changeInstance: PHChange) {

		guard let changes = changeInstance.changeDetails(for: fetchResult)
			else { return }

		// Change notifications may originate from a background queue.
		// As such, re-dispatch execution to the main queue before acting
		// on the change, so you can update the UI.
		DispatchQueue.main.sync {
			// Hang on to the new fetch result.
			fetchResult = changes.fetchResultAfterChanges

			// If we have incremental changes, animate them in the collection view.
			if changes.hasIncrementalChanges {
				guard let collectionView = self.collectionView else { fatalError() }

				// Handle removals, insertions, and moves in a batch update.
				collectionView.performBatchUpdates({
					if let removed = changes.removedIndexes, !removed.isEmpty {
						collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
					}
					if let inserted = changes.insertedIndexes, !inserted.isEmpty {
						collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
					}
					changes.enumerateMoves { fromIndex, toIndex in
						collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
												to: IndexPath(item: toIndex, section: 0))
					}
				})

				// We are reloading items after the batch update since `PHFetchResultChangeDetails.changedIndexes` refers to
				// items in the *after* state and not the *before* state as expected by `performBatchUpdates(_:completion:)`.
				if let changed = changes.changedIndexes, !changed.isEmpty {
					collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
				}
			} else {
				// Reload the collection view if incremental changes are not available.
				collectionView.reloadData()
			}
			resetCachedAssets()
		}
	}
}
