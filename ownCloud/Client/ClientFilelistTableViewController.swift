//
//  ClientFilelistTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 21.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ClientFilelistTableViewController: UITableViewController {

	var progressSummarizer : ProgressSummarizer?
	private var _actionProgressHandler : ActionProgressHandler?

	func makeActionProgressHandler() -> ActionProgressHandler {
		if _actionProgressHandler == nil {
			_actionProgressHandler = { [weak self] (progress, publish) in
				if publish {
					self?.progressSummarizer?.startTracking(progress: progress)
				} else {
					self?.progressSummarizer?.stopTracking(progress: progress)
				}
			}
		}

		return _actionProgressHandler!
	}
}
