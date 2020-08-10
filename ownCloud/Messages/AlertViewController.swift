//
//  AlertViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.03.20.
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
import ownCloudAppShared

class AlertViewController: UIViewController, Themeable {
	var localizedHeader : String?
	var localizedTitle : String
	var localizedDescription : String

	var options : [AlertOption]
	private var chosenOption : AlertOption?

	var alertView : AlertView?

	var dismissHandler : (() -> Void)?

	init(localizedHeader: String? = nil, localizedTitle: String, localizedDescription: String, options: [AlertOption], dismissHandler: (() -> Void)? = nil) {
		self.localizedHeader = localizedHeader
		self.localizedTitle = localizedTitle
		self.localizedDescription = localizedDescription
		self.options = options

		super.init(nibName: nil, bundle: nil)

		self.dismissHandler = dismissHandler

		for option in self.options {
			let existingHandler = option.handler

			option.handler = { [weak self] (view, option) in
				existingHandler(view, option)
				self?.chosenOption = option
				self?.dismiss(animated: true, completion: nil)
			}
		}
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func loadView() {
		alertView = AlertView(localizedHeader: localizedHeader, localizedTitle: localizedTitle, localizedDescription: localizedDescription, options: options)
		self.view = alertView
	}

	override func viewDidLoad() {
		Theme.shared.register(client: self, applyImmediately: true)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		becomeFirstResponder()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		if chosenOption == nil, let dismissHandler = dismissHandler {
			OnMainThread {
				dismissHandler()
			}
		}
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
