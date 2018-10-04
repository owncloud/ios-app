//
//  PDFThumbnailsCollectionViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import PDFKit

class PDFThumbnailsCollectionViewController: UICollectionViewController {

    var pdfDocument: PDFDocument?
    var themeCollection: ThemeCollection?

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.register(PDFThumbnailCollectionViewCell.self,
                                      forCellWithReuseIdentifier: PDFThumbnailCollectionViewCell.identifier)

        if self.themeCollection != nil {
            self.collectionView!.applyThemeCollection(self.themeCollection!)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        let thumbnailSize = floor(self.view.bounds.size.width * 0.3)
        let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout
        flowLayout?.itemSize = CGSize(width: thumbnailSize, height: thumbnailSize)
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

        if let pdfPage = self.pdfDocument?.page(at: indexPath.item) {
            cell?.setup(with: pdfPage)
        }
        return cell!
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let pdfPage = self.pdfDocument?.page(at: indexPath.item) {
            self.dismiss(animated: true) {
                NotificationCenter.default.post(name: PDFViewerViewController.PDFGoToPageNotification.name, object: pdfPage)
            }
        }
    }
}
