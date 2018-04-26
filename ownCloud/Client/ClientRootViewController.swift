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
	let bookmark : OCBookmark
	var core : OCCore?
	var filesNavigationController : ThemeNavigationController?
	var progressBar : CollapsibleProgressBar?
	var progressSummarizer : ProgressSummarizer?

	init(bookmark inBookmark: OCBookmark) {
		let openProgress = Progress()

		bookmark = inBookmark

		super.init(nibName: nil, bundle: nil)

		progressSummarizer = ProgressSummarizer.shared(forBookmark: inBookmark)
		if progressSummarizer != nil {
			progressSummarizer?.addObserver(self) { [weak self] (summarizer, summary) in
				var useSummary : ProgressSummary = summary

				if (summary.progress == 1) && (summarizer.fallbackSummary != nil) {
					useSummary = summarizer.fallbackSummary ?? summary
				}

				self?.progressBar?.update(with: useSummary.message, progress: Float(useSummary.progress))

				self?.progressBar?.autoCollapse = (summarizer.fallbackSummary == nil) || (useSummary.progressCount == 0)
			}
		}

		openProgress.localizedDescription = "Connecting…".localized
		progressSummarizer?.startTracking(progress: openProgress)

		core = CoreManager.shared.requestCoreForBookmark(bookmark, completion: { (_, error) in
			if error == nil {
				self.coreReady()
			}

			openProgress.localizedDescription = "Connected.".localized
			openProgress.completedUnitCount = 1
			openProgress.totalUnitCount = 1

			self.progressSummarizer?.stopTracking(progress: openProgress)
		})
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		ProgressSummarizer.shared(forBookmark: bookmark).removeObserver(self)

		CoreManager.shared.returnCoreForBookmark(bookmark, completion: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		filesNavigationController = ThemeNavigationController()
		filesNavigationController?.navigationBar.isTranslucent = false
		filesNavigationController?.tabBarItem.title = "Browse".localized
		filesNavigationController?.tabBarItem.image = Theme.shared.image(for: "folder", size: CGSize.init(width: 25, height: 25))

		progressBar = CollapsibleProgressBar(frame: CGRect.zero)
		progressBar?.translatesAutoresizingMaskIntoConstraints = false

		self.view.addSubview(progressBar!)

		progressBar?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
		progressBar?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
		progressBar?.bottomAnchor.constraint(equalTo: self.tabBar.topAnchor).isActive = true

		self.tabBar.applyThemeCollection(Theme.shared.activeCollection)

		self.viewControllers = [filesNavigationController] as? [UIViewController]
	}

	func logoutBarButtonItem() -> UIBarButtonItem {
		return UIBarButtonItem(title: "Disconnect".localized, style: .plain, target: self, action: #selector(logout(_:)))
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
