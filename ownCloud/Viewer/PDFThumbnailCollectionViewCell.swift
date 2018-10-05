//
//  PDFThumbnailCollectionViewCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import PDFKit

class PDFThumbnailCollectionViewCell: UICollectionViewCell {
    static let identifier = "PDFThumbnailCollectionViewCell"

    fileprivate let pageLabelBottomMargin: CGFloat = 5
    fileprivate let pageLabelHeightMultiplier: CGFloat = 0.1

    var imageView: UIImageView?
    var pageLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    fileprivate func setupSubviews() {
        imageView = UIImageView()
        imageView?.translatesAutoresizingMaskIntoConstraints = false
        imageView?.contentMode = .scaleAspectFit
        self.contentView.addSubview(imageView!)

        pageLabel = UILabel()
        pageLabel?.backgroundColor = UIColor.clear
        pageLabel?.textColor = UIColor.black
        pageLabel?.textAlignment = .center
        pageLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
        pageLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.imageView?.addSubview(pageLabel!)

        imageView!.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        imageView!.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        imageView!.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        imageView!.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        pageLabel!.bottomAnchor.constraint(equalTo: imageView!.bottomAnchor, constant: -pageLabelBottomMargin).isActive = true
        pageLabel!.rightAnchor.constraint(equalTo: imageView!.rightAnchor).isActive = true
        pageLabel!.leftAnchor.constraint(equalTo: imageView!.leftAnchor).isActive = true
        pageLabel!.heightAnchor.constraint(equalTo: imageView!.heightAnchor, multiplier:pageLabelHeightMultiplier).isActive = true
    }

    func setup(with page:PDFPage) {
        imageView?.image = page.thumbnail(of: self.bounds.size, for: .cropBox)
        pageLabel?.text = page.label
    }
}
