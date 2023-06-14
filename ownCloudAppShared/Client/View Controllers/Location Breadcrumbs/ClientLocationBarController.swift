//
//  ClientLocationBarController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.01.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension ThemeCSSSelector {
	static let locationBar = ThemeCSSSelector(rawValue: "locationBar")
}

open class ClientLocationBarController: UIViewController, Themeable {
	public var location: OCLocation
	public var clientContext: ClientContext

	public var seperatorView: ThemeCSSView?
	public var segmentView: SegmentView?

	public init(clientContext: ClientContext, location: OCLocation) {
		self.location = location
		self.clientContext = clientContext

		super.init(nibName: nil, bundle: nil)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func loadView() {
		view = ThemeCSSView(withSelectors: [.toolbar, .locationBar])
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		seperatorView = ThemeCSSView(withSelectors: [.separator])
		seperatorView?.translatesAutoresizingMaskIntoConstraints = false

		segmentView = SegmentView(with: composeSegments(location: location, in: clientContext), truncationMode: .truncateTail, scrollable: true, limitVerticalSpaceUsage: true)
		segmentView?.translatesAutoresizingMaskIntoConstraints = false

		segmentView?.itemSpacing = 0

		if let segmentView, let seperatorView {
			let seperatorThickness: CGFloat = 0.5

			view.addSubview(segmentView)
			view.addSubview(seperatorView)

			NSLayoutConstraint.activate([
				seperatorView.topAnchor.constraint(equalTo: view.topAnchor),
				seperatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				seperatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
				seperatorView.heightAnchor.constraint(equalToConstant: seperatorThickness),

				segmentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
				segmentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
				segmentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9 + seperatorThickness), // + 1 for the seperatorView
				segmentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
			])
		}
	}

	var _themeRegistered: Bool = false
	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if !_themeRegistered {
			_themeRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	func composeSegments(location: OCLocation, in clientContext: ClientContext) -> [SegmentViewItem] {
		return OCLocation.composeSegments(breadcrumbs: location.breadcrumbs(in: clientContext), in: clientContext, segmentConfigurator: { breadcrumb, segment in
			// Make breadcrumbs tappable using the provided action's .actionBlock
			if breadcrumb.actionBlock != nil {
				segment.gestureRecognizers = [
					ActionTapGestureRecognizer(action: { [weak self] _ in
						if let clientContext = self?.clientContext {
							breadcrumb.run(options: [.clientContext : clientContext])
						}
					})
				]
			}
		})
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		seperatorView?.apply(css: collection.css, properties: [.fill])

		if let backgroundFillColor = collection.css.getColor(.fill, for: view) {
			segmentView?.scrollViewOverlayGradientColor = backgroundFillColor.cgColor
		}
	}
}
