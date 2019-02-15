//
//  DisplayViewerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class DisplayViewerViewController: UIViewController {

	weak var delegate: DisplayViewerDelegate?
	weak var dataSource: DisplayViewerDataSource?

	var item: OCItem? {
		didSet {
			if item != nil {

			}
		}
	}

	private var nonSupportedView: UIView?

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		delegate?.setNavigationBarItemsFor(viewController: self)
		if let item = dataSource?.itemFor(viewController: self) {
			self.item = item
		} else {
			if let nonSupportedView = dataSource?.nonSupportedItemView() {
				self.nonSupportedView = nonSupportedView
				self.nonSupportedView?.translatesAutoresizingMaskIntoConstraints = false
				self.view.addSubview(self.nonSupportedView!)

				NSLayoutConstraint.activate([
					self.nonSupportedView!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
					self.nonSupportedView!.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
					self.nonSupportedView!.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
					self.nonSupportedView!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
					])
			}
		}
    }
}
