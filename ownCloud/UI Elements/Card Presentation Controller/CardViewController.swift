//
//  CardViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.06.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class CardViewController: UIViewController, Themeable, CardPresentationSizing {
	deinit {
		Theme.shared.unregister(client: self)
	}

	override func loadView() {
		definesPresentationContext = true

		view = UIView()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)

		view.layoutIfNeeded()
	}

	// MARK: - Themeable
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		view.backgroundColor = collection.tableBackgroundColor
	}

	// MARK: - CardPresentationSizing
	func cardPresentationSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
		var size : CGSize = CGSize(width: 0, height: 0)

		if self.view != nil {
			size.width = targetSize.width

			let bodySize = view.systemLayoutSizeFitting(CGSize(width: targetSize.width, height: targetSize.height),
									   withHorizontalFittingPriority: horizontalFittingPriority,
									   verticalFittingPriority: .defaultLow)
			size.height += bodySize.height
		}

		return size
	}

	var fitsOnScreen: Bool = true
}
