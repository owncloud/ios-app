//
//  SortBar.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 31/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class SortBar: UIView, Themeable {

	var sortButton: ThemeButton

	override init(frame: CGRect) {
		sortButton = ThemeButton(frame: .zero)
		super.init(frame: frame)
		sortButton.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(sortButton)

		sortButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
		sortButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
		sortButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
		Theme.shared.register(client: self)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.sortButton.applyThemeCollection(collection)
		self.applyThemeCollection(collection)
	}
}
