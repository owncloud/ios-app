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

open class EmbeddingViewController: UIViewController {

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
	open var contentViewController: UIViewController? {
		willSet {
			contentViewController?.willMove(toParent: nil)
			contentViewController?.view.removeFromSuperview()
			contentViewController?.removeFromParent()

			contentViewControllerConstraints = nil
		}
		didSet {
			if let contentViewController = contentViewController, let contentViewControllerView = contentViewController.view {
				addChild(contentViewController)
				view.addSubview(contentViewControllerView)
				contentViewControllerView.translatesAutoresizingMaskIntoConstraints = false
				if let customEmbedder = self as? CustomViewControllerEmbedding {
					contentViewControllerConstraints = customEmbedder.constraintsForEmbedding(contentView: contentViewController.view)
				} else {
					contentViewControllerConstraints = view.embed(toFillWith: contentViewController.view, enclosingAnchors: view.defaultAnchorSet)
				}
				contentViewController.didMove(toParent: self)
			}
		}
	}
}
