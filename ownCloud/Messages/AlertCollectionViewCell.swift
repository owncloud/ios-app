//
//  AlertCollectionViewCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.05.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

class AlertCollectionViewCell: UICollectionViewCell, Themeable {
	var alertView : AlertView? {
		willSet {
			if alertView != nil {
				alertView?.removeFromSuperview()
			}
		}
		didSet {
			if let alertView = alertView {
				self.contentView.addSubview(alertView)

				NSLayoutConstraint.activate([
					alertView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
					alertView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
					alertView.topAnchor.constraint(equalTo: contentView.topAnchor),
					alertView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
				])
			}
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.backgroundColor = collection.tableRowColors.backgroundColor
	}
}
