//
//  PDFSearchTableViewCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 18.09.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class PDFSearchTableViewCell: ThemeTableViewCell {

    var titleLabel = UILabel()
    var pageLabel = UILabel()

    static let identifier = "PDFSearchTableViewCell"

    fileprivate let layoutMargin: CGFloat = 20.0

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

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        pageLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.light)

        pageLabel.textAlignment = .right
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        pageLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        pageLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true

        titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: layoutMargin).isActive = true
        pageLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -layoutMargin).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: pageLabel.rightAnchor)

        pageLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.horizontal)
    }

    // MARK: - Theme support
    override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
        let itemState = ThemeItemState(selected: self.isSelected)

        self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
        self.pageLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
    }
}
