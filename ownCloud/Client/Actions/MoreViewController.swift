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

class MoreViewController: UIViewController {

	private var item: OCItem
	private var core: OCCore

	private var headerView: UIView
	private var viewController: UIViewController

	init(item: OCItem, core: OCCore, header: UIView, viewController: UIViewController) {
		self.item = item
		self.core = core
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
			headerView.topAnchor.constraint(equalTo: view.topAnchor),
			headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
			])

		view.addSubview(viewController.view)
		viewController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			viewController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			viewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
			viewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
			viewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)
			])

		headerView.layer.shadowColor = UIColor.black.cgColor
		headerView.layer.shadowOpacity = 0.1
		headerView.layer.shadowRadius = 10
		headerView.layer.cornerRadius = 10
		headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

		// Drag view
		let dragView: UIView = UIView()
		dragView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(dragView)
		dragView.layer.cornerRadius = 2.5

		NSLayoutConstraint.activate([
			dragView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
			dragView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			dragView.widthAnchor.constraint(equalToConstant: 50),
			dragView.heightAnchor.constraint(equalToConstant: 5)
			])
		dragView.backgroundColor = .lightGray
	}
}

extension MoreViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.headerView.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
	}
}
