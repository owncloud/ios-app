//
//  HeaderActionTableViewCell.swift
//  ownCloud
//
//  Created by Matthias Hühne on 20.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class HeaderActionTableViewCell : UITableViewCell {
	public var headerLabel : UILabel = UILabel()
	public var actionLabel : UILabel = UILabel()

	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func prepareViewAndConstraints() {
		self.selectionStyle = .default

		headerLabel.translatesAutoresizingMaskIntoConstraints = false
		actionLabel.translatesAutoresizingMaskIntoConstraints = false

		headerLabel.font = UIFont.systemFont(ofSize: 14)
		headerLabel.adjustsFontForContentSizeCategory = true

		actionLabel.font = UIFont.systemFont(ofSize: 17)
		actionLabel.adjustsFontForContentSizeCategory = true

		self.contentView.addSubview(headerLabel)
		self.contentView.addSubview(actionLabel)

		headerLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -15).isActive = true
		actionLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -15).isActive = true
		headerLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 15).isActive = true
		actionLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 15).isActive = true

		headerLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
		headerLabel.bottomAnchor.constraint(equalTo: actionLabel.topAnchor, constant: -10).isActive = true
		actionLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10).isActive = true

		headerLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
		actionLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.vertical)
	}
}
