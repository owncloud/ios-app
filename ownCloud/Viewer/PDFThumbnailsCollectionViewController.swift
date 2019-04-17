//
//  PDFThumbnailsCollectionViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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
import PDFKit
import ownCloudSDK

class PDFThumbnailsCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching, Themeable {

    fileprivate let thumbnailSizeMultiplierLandscape: CGFloat = 0.2
	fileprivate let thumbnailSizeMultiplierPortrait: CGFloat = 0.3

    fileprivate let maxThumbnailCachedCount: UInt = 100
    fileprivate let verticalInset: CGFloat = 8.0
    fileprivate let horizontalInset: CGFloat = 4.0
	fileprivate let layout = UICollectionViewFlowLayout()

    var pdfDocument: PDFDocument?
    let thumbnailCache = OCCache<NSString, UIImage>()
    var thumbnailFetchQueue = OperationQueue()
    var fetchOperations : [IndexPath : BlockOperation] = [:]

    init() {
        layout.scrollDirection = .vertical
		layout.sectionInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)

        thumbnailCache.countLimit = maxThumbnailCachedCount
        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.prefetchDataSource = self

        // Register cell classes
        self.collectionView!.register(PDFThumbnailCollectionViewCell.self,
                                      forCellWithReuseIdentifier: PDFThumbnailCollectionViewCell.identifier)
		self.collectionView.contentInsetAdjustmentBehavior = .automatic
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Theme.shared.register(client: self)

        recalculateThumbnailSize()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Theme.shared.unregister(client: self)
    }

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// These lines mitigates the issue with incorrect layout of child view controller
		if let parentView = self.parent?.view {
			self.view.frame = parentView.frame
		}
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { (_) in
			// do nothing for now, later useful animations can be added
		}, completion: { [weak self] (_) in
			// rotation has finished
			self?.recalculateThumbnailSize()
		})
	}

    // MARK: - Themeable support

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
        self.collectionView!.applyThemeCollection(collection)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pdfDocument?.pageCount ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PDFThumbnailCollectionViewCell.identifier, for: indexPath) as? PDFThumbnailCollectionViewCell
        let (image, label) =  getCachedThumbnailOrFetchAsync(at: indexPath)
        cell?.imageView?.image = image
        cell?.pageLabel?.text = label
        return cell!
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let pdfPage = self.pdfDocument?.page(at: indexPath.item) {
            self.dismiss(animated: true) {
                NotificationCenter.default.post(name: PDFViewerViewController.PDFGoToPageNotification.name, object: pdfPage)
            }
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateVisibleCells()
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateVisibleCells()
    }

    // МАРК: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {

        for indexPath in indexPaths {
            if let pdfPage = self.pdfDocument?.page(at: indexPath.item) {
                if let layout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                    fetchThumbnail(for: pdfPage, indexPath: indexPath, size: layout.itemSize)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {

        for indexPath in indexPaths {
            cancelFetchingThumbnail(indexPath: indexPath)
        }
    }

    // MARK: - Private methods

	fileprivate func recalculateThumbnailSize(newTotalWidth: CGFloat = -1.0) {
		let orientation = UIDevice.current.orientation
		var viewWidth: CGFloat = 0.0

		if newTotalWidth > 0 {
			viewWidth = newTotalWidth
		} else {
			// Heads up! bounds on iPad are incorrect for the own view controller's view
			if UIDevice.current.isIpad() {
				viewWidth = parent!.view.bounds.width
			} else {
				viewWidth = view.bounds.inset(by: view.safeAreaInsets).width
			}
		}

		let width = viewWidth - (layout.sectionInset.left + layout.sectionInset.right)

		let multiplier = (orientation.isPortrait || UIDevice.current.isIpad()) ? thumbnailSizeMultiplierPortrait : thumbnailSizeMultiplierLandscape
		let thumbnailWidth = floor(width * multiplier) - horizontalInset
		var thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth)

		// Try to correct cell size to match size of the actual generated thumbnails
		if let pdfPage = self.pdfDocument?.page(at: 0) {
			let thumbnail = pdfPage.thumbnail(of: thumbnailSize, for: .cropBox)
			thumbnailSize = thumbnail.size
		}

		let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout
		flowLayout?.itemSize = thumbnailSize
	}

    fileprivate func fetchThumbnail(for page:PDFPage, indexPath:IndexPath, size:CGSize) {
        let blockOperation = BlockOperation()
        weak var weakBlockOperation = blockOperation

        blockOperation.addExecutionBlock { [weak self] in
            let thumbnailImage = page.thumbnail(of: size, for: .cropBox)
            self?.thumbnailCache.setObject(thumbnailImage, forKey: page.label! as NSString)
            if (weakBlockOperation?.isCancelled)! {
                return
            }
            DispatchQueue.main.async {
                if let cell : PDFThumbnailCollectionViewCell = self?.collectionView?.cellForItem(at: indexPath) as? PDFThumbnailCollectionViewCell {
                    if let visibleCells = self?.collectionView?.visibleCells {
                        if visibleCells.contains(cell) {
                            cell.imageView?.image = thumbnailImage
                            cell.pageLabel?.text = page.label
                        }
                    }
                }
            }
            self?.fetchOperations[indexPath] = nil
        }
        thumbnailFetchQueue.addOperation(blockOperation)
    }

    fileprivate func cancelFetchingThumbnail(indexPath:IndexPath) {
        if fetchOperations[indexPath] != nil {
            let blockOperation = fetchOperations[indexPath]
            blockOperation?.cancel()
            fetchOperations[indexPath] = nil
        }
    }

    fileprivate func getCachedThumbnailOrFetchAsync(at:IndexPath) -> (UIImage?, String?) {
        if let pdfPage = self.pdfDocument?.page(at: at.item) {
            let thumbnailImage = thumbnailCache.object(forKey: pdfPage.label! as NSString)
            if thumbnailImage != nil {
                return (thumbnailImage, pdfPage.label)
            } else {
                if let layout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                    fetchThumbnail(for: pdfPage, indexPath: at, size: layout.itemSize)
                }
            }
        }
        return (nil, nil)
    }

    fileprivate func updateVisibleCells() {
        for indexPath in self.collectionView!.indexPathsForVisibleItems {
            let cell = self.collectionView!.cellForItem(at: indexPath)
            if let pdfThumbnailCell = cell as? PDFThumbnailCollectionViewCell {
                if pdfThumbnailCell.imageView?.image == nil {
                    let (image, label) = getCachedThumbnailOrFetchAsync(at: indexPath)
                    pdfThumbnailCell.imageView?.image = image
                    pdfThumbnailCell.pageLabel?.text = label
                }
            }
        }
    }
}
