//
//  PDFTocTableViewCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 05.10.2018.
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

class PDFTocTableViewCell: ThemeTableViewCell {

    var titleLabel = UILabel()
    var pageLabel = UILabel()
    var titleLeftConstraint: NSLayoutConstraint?

    static let identifier = "PDFTocTableViewCell"

    fileprivate let layoutMargin: CGFloat = 15.0
    fileprivate let pageFontSize: CGFloat = 15.0

    // Array of fonts to be used at different chapter nesting levels
    fileprivate static let titleFonts = [
        UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.bold),
        UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold),
        UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold),
        UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
    ]

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviewsAndConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviewsAndConstraints()
    }

    fileprivate func setupSubviewsAndConstraints() {

        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(pageLabel)

        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        pageLabel.font = UIFont.systemFont(ofSize: pageFontSize, weight: UIFont.Weight.light)
        pageLabel.textAlignment = .right
        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        titleLeftConstraint = titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: layoutMargin)
        titleLeftConstraint?.isActive = true

        pageLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        pageLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        pageLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -layoutMargin).isActive = true

        pageLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true

        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: UILayoutConstraintAxis.horizontal)
        pageLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.horizontal)
    }

    // MARK: - Theme support

    override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
        let itemState = ThemeItemState(selected: self.isSelected)

        self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
        self.pageLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
    }

    func setup(with tocItem:PDFTocItem) {
        self.titleLabel.text = tocItem.label
        if let page = tocItem.page {
            self.pageLabel.text = page.label
        }

        // Indent the title according to the nesting level
        titleLeftConstraint?.constant = layoutMargin * CGFloat(tocItem.level)

        // Use smaller fonts for the sub-chapters
        let fontIndex = min(tocItem.level, (PDFTocTableViewCell.titleFonts.count - 1))
        titleLabel.font = PDFTocTableViewCell.titleFonts[fontIndex]
    }
}
