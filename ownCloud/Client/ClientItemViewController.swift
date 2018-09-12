//
//  ClientItemViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 22.06.18.
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
import WebKit
import ownCloudSDK

class ClientItemViewController: UIViewController {
	var webView : WKWebView?
	var file : OCFile?
	var item : OCItem?

	override func loadView() {
		let rootView = UIView()

		webView = WKWebView()
		webView?.translatesAutoresizingMaskIntoConstraints = false

		rootView.addSubview(webView!)

		webView?.leftAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leftAnchor).isActive = true
		webView?.rightAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.rightAnchor).isActive = true
		webView?.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor).isActive = true
		webView?.bottomAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.bottomAnchor).isActive = true

		self.view = rootView
	}

	override func viewDidLoad() {
		self.navigationItem.title = file?.url.lastPathComponent
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let fileURL = file?.url {
			webView?.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
		}
	}
}
