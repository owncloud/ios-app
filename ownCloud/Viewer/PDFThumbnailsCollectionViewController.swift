//
//  PDFThumbnailsCollectionViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import PDFKit
import ownCloudSDK

class PDFThumbnailsCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {

    fileprivate let thumbnailSizeMultiplier: CGFloat = 0.3
    fileprivate let maxThumbnailCachedCount: UInt = 100

    var pdfDocument: PDFDocument?
    var themeCollection: ThemeCollection?
    let thumbnailCache = OCCache<NSString, UIImage>()
    var thumbnailFetchQueue = OperationQueue()
    var fetchOperations : [IndexPath : BlockOperation] = [:]

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
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

        if self.themeCollection != nil {
            self.collectionView!.applyThemeCollection(self.themeCollection!)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        let thumbnailWidth = floor(self.view.bounds.size.width * thumbnailSizeMultiplier)
        var thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth)

        // Try to correct cell size to match size of the actual generated thumbnails
        if let pdf = self.pdfDocument {
            if let pdfPage = pdf.page(at: 0) {
                let thumbnail = pdfPage.thumbnail(of: thumbnailSize, for: .cropBox)
                thumbnailSize = thumbnail.size
            }
        }

        let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.itemSize = thumbnailSize
        super.viewWillAppear(animated)
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

    fileprivate func fetchThumbnail(for page:PDFPage, indexPath:IndexPath, size:CGSize) {
        let blockOperation = BlockOperation()
        weak var weakBlockOperation = blockOperation

        blockOperation.addExecutionBlock { [unowned self] in
            let thumbnailImage = page.thumbnail(of: size, for: .cropBox)
            self.thumbnailCache.setObject(thumbnailImage, forKey: page.label! as NSString)
            if (weakBlockOperation?.isCancelled)! {
                return
            }
            DispatchQueue.main.async {
                if let cell : PDFThumbnailCollectionViewCell = self.collectionView?.cellForItem(at: indexPath) as? PDFThumbnailCollectionViewCell {
                    if let visibleCells = self.collectionView?.visibleCells {
                        if visibleCells.contains(cell) {
                            cell.imageView?.image = thumbnailImage
                            cell.pageLabel?.text = page.label
                        }
                    }
                }
            }
            self.fetchOperations[indexPath] = nil
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
