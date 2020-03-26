//
//  PDFThumbnailCollectionViewCell.swift
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

class PDFThumbnailCollectionViewCell: UICollectionViewCell, UIPointerInteractionDelegate {
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
        self.backgroundColor = UIColor.lightGray

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

		if #available(iOS 13.4, *) {
			_ = UIPointerInteraction(delegate: self)
			customPointerInteraction(on: self, pointerInteractionDelegate: self)
		}
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView?.image = nil
        self.pageLabel?.text = ""
    }

	// MARK: - UIPointerInteractionDelegate
	@available(iOS 13.4, *)
	func customPointerInteraction(on view: UIView, pointerInteractionDelegate: UIPointerInteractionDelegate) {
		let pointerInteraction = UIPointerInteraction(delegate: pointerInteractionDelegate)
		view.addInteraction(pointerInteraction)
	}

	@available(iOS 13.4, *)
	func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?

        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
			pointerStyle = UIPointerStyle(effect: UIPointerEffect.hover(targetedPreview, preferredTintMode: .overlay, prefersShadow: false, prefersScaledContent: true))
        }
        return pointerStyle
    }
}
