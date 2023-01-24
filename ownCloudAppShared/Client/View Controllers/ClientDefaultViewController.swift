//
//  ClientDefaultViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 28.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp

public class ClientDefaultViewController: UIViewController, Themeable {
	public override func loadView() {
		let rootView = UIView()

		let logoView = VectorImageView()
		logoView.translatesAutoresizingMaskIntoConstraints = false
		logoView.vectorImage = Theme.shared.tvgImage(for: "owncloud-logo")

		rootView.embed(centered: logoView, minimumInsets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20), fixedSize: CGSize(width: 480, height: 480), minimumSize: CGSize(width: 240, height: 180), maximumSize: CGSize(width: 280, height: 280))

		self.view = rootView
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self, applyImmediately: true)
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}
