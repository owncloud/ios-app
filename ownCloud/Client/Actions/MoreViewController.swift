//
//  MoreViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 25/07/2018.
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
import ownCloudSDK

class MoreViewController: UIViewController, CardPresentationSizing {

	private var item: OCItem?
	private weak var core: OCCore?

	private var headerView: UIView
	private var viewController: UIViewController

	var fitsOnScreen : Bool = false {
		didSet {
			if let scrollView = viewController.view as? UIScrollView {
				scrollView.isScrollEnabled = !fitsOnScreen
			}
		}
	}

	init(item: OCItem, core: OCCore, header: UIView, viewController: UIViewController) {
		self.item = item
		self.core = core
		self.headerView = header
		self.viewController = viewController

		super.init(nibName: nil, bundle: nil)
	}

	init(header: UIView, viewController: UIViewController) {
		self.headerView = header
		self.viewController = viewController

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		definesPresentationContext = true

		Theme.shared.register(client: self)

		headerView.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(headerView)
		NSLayoutConstraint.activate([
			headerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			headerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
			headerView.topAnchor.constraint(equalTo: view.topAnchor)
		])

		view.addSubview(viewController.view)
		viewController.view.translatesAutoresizingMaskIntoConstraints = false

		let bottomConstraint = viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		bottomConstraint.priority = UILayoutPriority(rawValue: 999)

		NSLayoutConstraint.activate([
			bottomConstraint,
			viewController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			viewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
			viewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor)
		])

		headerView.layer.shadowColor = UIColor.black.cgColor
		headerView.layer.shadowOpacity = 0.1
		headerView.layer.shadowRadius = 10
		headerView.layer.cornerRadius = 10
		headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

		self.view.layoutIfNeeded()
	}

	func cardPresentationSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
		var size : CGSize = CGSize(width: 0, height: 0)

		if self.view != nil {
			let headerSize = headerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .defaultHigh, verticalFittingPriority: .defaultLow)

			size.width = targetSize.width
			size.height = headerSize.height

			if let scrollView = viewController.view as? UIScrollView {
				size.height += scrollView.contentSize.height
			} else {
				let bodySize = viewController.view.systemLayoutSizeFitting(CGSize(width: targetSize.width, height: targetSize.height-headerSize.height),
										   withHorizontalFittingPriority: horizontalFittingPriority,
										   verticalFittingPriority: verticalFittingPriority)
				size.height += bodySize.height
			}
		}

		return size
	}

    @objc func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
    }
    
	override func viewDidLayoutSubviews() {
		if self.view.superview != nil {
			self.preferredContentSize = cardPresentationSizeFitting(CGSize(width: UIView.layoutFittingExpandedSize.width, height: UIView.layoutFittingExpandedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)
		}

		super.viewDidLayoutSubviews()
	}
}

extension MoreViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.headerView.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
	}
}
