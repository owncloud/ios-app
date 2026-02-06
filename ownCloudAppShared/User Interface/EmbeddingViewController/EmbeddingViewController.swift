//
//  EmbeddingViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 06.12.22.
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

public protocol CustomViewControllerEmbedding: EmbeddingViewController {
	func constraintsForEmbedding(contentView: UIView) -> [NSLayoutConstraint]
}

open class EmbeddingViewController: UIViewController, Themeable {

	// MARK: - Content View Controller handling
	private var contentViewControllerConstraints : [NSLayoutConstraint]? {
		willSet {
			if let contentViewControllerConstraints = contentViewControllerConstraints {
				NSLayoutConstraint.deactivate(contentViewControllerConstraints)
			}
		}
		didSet {
			if let contentViewControllerConstraints = contentViewControllerConstraints {
				NSLayoutConstraint.activate(contentViewControllerConstraints)
			}
		}
	}

	open func constraintsForEmbedding(contentViewController: UIViewController) -> [NSLayoutConstraint] {
		if let customEmbedder = self as? CustomViewControllerEmbedding {
			return customEmbedder.constraintsForEmbedding(contentView: contentViewController.view)
		} else {
			return view.embed(toFillWith: contentViewController.view, enclosingAnchors: view.defaultAnchorSet)
		}
	}

	open func addContentViewControllerSubview(_ contentViewControllerView: UIView) {
		view.addSubview(contentViewControllerView)
	}

	@objc open var contentViewController: UIViewController? {
		willSet {
			contentViewController?.willMove(toParent: nil)
			contentViewController?.view.removeFromSuperview()
			contentViewController?.removeFromParent()

			contentViewControllerConstraints = nil
		}
		didSet {
			if let contentViewController, let contentViewControllerView = contentViewController.view {
				addChild(contentViewController)
				addContentViewControllerSubview(contentViewControllerView)
				contentViewControllerView.translatesAutoresizingMaskIntoConstraints = false
				contentViewControllerConstraints = constraintsForEmbedding(contentViewController: contentViewController)
				contentViewController.didMove(toParent: self)
			}
		}
	}

	// MARK: - Themeing
	private var themeRegistered = false
	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if !themeRegistered {
			Theme.shared.register(client: self, applyImmediately: true)
			themeRegistered = true
		}
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		overrideUserInterfaceStyle = collection.css.getUserInterfaceStyle()
	}
}
