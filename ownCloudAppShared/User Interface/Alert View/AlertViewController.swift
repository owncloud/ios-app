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

open class AlertViewController: UIViewController, Themeable {
	open var localizedHeader : String?
	open var localizedTitle : String
	open var localizedDescription : String

	open var options : [AlertOption]
	private var chosenOption : AlertOption?

	open var alertView : AlertView?

	open var dismissHandler : (() -> Void)?

	public init(localizedHeader: String? = nil, localizedTitle: String, localizedDescription: String, options: [AlertOption], dismissHandler: (() -> Void)? = nil) {
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

	override public func loadView() {
		alertView = AlertView(localizedHeader: localizedHeader, localizedTitle: localizedTitle, localizedDescription: localizedDescription, options: options)
		self.view = alertView
	}

	override public func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self, applyImmediately: true)
	}

	override public func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		becomeFirstResponder()
	}

	override public func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		if chosenOption == nil, let dismissHandler = dismissHandler {
			OnMainThread {
				dismissHandler()
			}
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
