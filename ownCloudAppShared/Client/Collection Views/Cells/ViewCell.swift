//
//  ViewCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 31.05.22.
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

class ViewCell: ThemeableCollectionViewListCell {
	private var _previousSeparatorLayoutGuideConstraints: [NSLayoutConstraint]?
	var hostedView: UIView? {
		willSet {
			if let previousSperatorLayoutGuideConstraints = _previousSeparatorLayoutGuideConstraints {
				NSLayoutConstraint.deactivate(previousSperatorLayoutGuideConstraints)
				_previousSeparatorLayoutGuideConstraints = nil
			}

			if hostedView != newValue {
				hostedView?.removeFromSuperview()
			}
		}

		didSet {
			if let hostedView = hostedView, hostedView != oldValue {
				hostedView.layoutIfNeeded()

				contentView.addSubview(hostedView)

				var constraints : [NSLayoutConstraint] = [
					// Fill cell.contentView
					// -> these constraints are applied with .defaultHigh priority (not the default of .required) to not trigger
					//    an unsatisfiable constraints warning in case a cell is re-used and the new view's size conflicts with the
					//    system's "UIView-Encapsulated-Layout-Height" constraint
					hostedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).with(priority: .defaultHigh),
					hostedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).with(priority: .defaultHigh),
					hostedView.topAnchor.constraint(equalTo: contentView.topAnchor).with(priority: .defaultHigh),
					hostedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).with(priority: .defaultHigh)
				]
				var layoutGuideConstraints: [NSLayoutConstraint]?

				if let customizer = hostedView.separatorLayoutGuideCustomizer {
					// Use custom constraints
					layoutGuideConstraints = customizer.customizer(self, hostedView)
				} else {
					layoutGuideConstraints = [
						// Extend cell seperator to contentView.leadingAnchor
						separatorLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
					]
				}

				if let layoutGuideConstraints = layoutGuideConstraints {
					_previousSeparatorLayoutGuideConstraints = layoutGuideConstraints
					constraints += layoutGuideConstraints
				}

				NSLayoutConstraint.activate(constraints)
			}
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		hostedView = nil
	}

	static func registerCellProvider() {
		let itemListCellRegistration = UICollectionView.CellRegistration<ViewCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				cell.hostedView = item as? UIView
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .view, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: itemListCellRegistration, for: indexPath, item: itemRef)
		}))
	}
}

class SeparatorLayoutGuideCustomizer : NSObject {
	typealias Customizer = (_ viewCell: ViewCell, _ view: UIView) -> [NSLayoutConstraint]

	var customizer: Customizer

	init(with customizer: @escaping Customizer) {
		self.customizer = customizer
		super.init()
	}
}

extension UIView {
	private static let associatedKeySeparatorLayoutGuideCustomizer = malloc(1)!

	var separatorLayoutGuideCustomizer: SeparatorLayoutGuideCustomizer? {
		get {
			return objc_getAssociatedObject(self, UIView.associatedKeySeparatorLayoutGuideCustomizer) as? SeparatorLayoutGuideCustomizer
		}

		set {
			objc_setAssociatedObject(self, UIView.associatedKeySeparatorLayoutGuideCustomizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}
}
