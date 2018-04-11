//
//  ClientViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.04.18.
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

class ClientRootViewController: UITabBarController {
	public let bookmark : OCBookmark
	public var core : OCCore?
	public var filesNavigationController : UINavigationController?

	public init(bookmark inBookmark: OCBookmark) {
		bookmark = inBookmark

		super.init(nibName: nil, bundle: nil)

		core = CoreManager.shared.requestCoreForBookmark(bookmark, completion: { (_, error) in
			if error == nil {
				self.coreReady()
			}
		})
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		CoreManager.shared.returnCoreForBookmark(bookmark, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		filesNavigationController = UINavigationController()
		filesNavigationController?.navigationBar.isTranslucent = false
		filesNavigationController?.view.backgroundColor = .white
		filesNavigationController?.tabBarItem.title = "Files"

		self.viewControllers = [filesNavigationController] as? [UIViewController]
	}

	override func viewWillAppear(_ animated: Bool) {
	}

	func logoutBarButtonItem() -> UIBarButtonItem {
		return (UIBarButtonItem(title: NSLocalizedString("Logout", comment: ""), style: .plain, target: self, action: #selector(logout(_:))))
	}

	@objc func logout(_: Any) {
		self.presentingViewController?.dismiss(animated: true, completion: nil)
	}

	func coreReady() {
		DispatchQueue.main.async {
			let queryViewController = ClientQueryViewController.init(core: self.core!, query: OCQuery.init(forPath: "/"))

			queryViewController.navigationItem.leftBarButtonItem = self.logoutBarButtonItem()

			self.filesNavigationController?.pushViewController(queryViewController, animated: false)
		}
	}
}
