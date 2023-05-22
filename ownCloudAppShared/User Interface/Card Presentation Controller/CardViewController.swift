//
//  CardViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.06.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

open class CardViewController: UIViewController, Themeable, CardPresentationSizing {
	deinit {
		Theme.shared.unregister(client: self)
	}

	override open func loadView() {
		definesPresentationContext = true

		view = UIView()
	}

	override open func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)

		view.layoutIfNeeded()
	}

	// MARK: - Themeable
	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		view.backgroundColor = collection.tableBackgroundColor
	}

	// MARK: - CardPresentationSizing
	open func cardPresentationSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
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

	open var fitsOnScreen: Bool = true
}
