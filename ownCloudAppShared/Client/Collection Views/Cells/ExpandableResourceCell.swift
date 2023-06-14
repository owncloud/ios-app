//
//  ExpandableResourceCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.22.
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
import ownCloudSDK

class ExpandableResourceCell: UICollectionViewListCell, Themeable {
	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
		configureLayout()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	private var _registered: Bool = false

	override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !_registered {
			_registered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.contentView.backgroundColor = collection.css.getColor(.fill, for: self)
		expandButton.tintColor = collection.css.getColor(.stroke, selectors: [.button], for: self)
	}

	var resourceView: UIView? {
		willSet {
			resourceView?.removeFromSuperview()
		}

		didSet {
			if let resourceView = resourceView {
				resourceView.translatesAutoresizingMaskIntoConstraints = false
				contentView.insertSubview(resourceView, belowSubview: expandButton)
				configureLayout()
			}
		}
	}

	var expandButton : UIButton = UIButton()
	var shadowView : ShadowBarView = ShadowBarView()

	var resourceEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

	let collapsedHeight: CGFloat = 192

	var expandItemImage : UIImage?
	var collapseItemImage : UIImage?

	var resource : OCResource? {
		didSet {
			(resource as? OCViewProvider)?.provideView(for: .zero, in: nil, completion: { [weak self] textView in
				self?.resourceView = textView
			})
		}
	}

	func configure() {
		self.cssSelectors = [.expandable]

		expandButton.translatesAutoresizingMaskIntoConstraints = false
		shadowView.translatesAutoresizingMaskIntoConstraints = false

		let configuration = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)

		expandItemImage = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: configuration)
		collapseItemImage = UIImage(systemName: "chevron.up.circle.fill", withConfiguration: configuration)

		expandButton.setImage(expandItemImage, for: .normal)
		expandButton.addAction(UIAction(handler: { [weak self] action in
			self?.openClose()
		}), for: .primaryActionTriggered)

		contentView.addSubview(expandButton)
		contentView.addSubview(shadowView)
		contentView.clipsToBounds = true

		collapsedConstraint = contentView.heightAnchor.constraint(lessThanOrEqualToConstant: collapsedHeight).with(priority: .required)
	}

	var collapsedConstraint: NSLayoutConstraint?

	func configureLayout() {
		guard let resourceView = resourceView else { return }

		NSLayoutConstraint.activate([
			resourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: resourceEdgeInsets.left),
			resourceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -resourceEdgeInsets.right),
			resourceView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: resourceEdgeInsets.top),
			resourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -resourceEdgeInsets.bottom).with(priority: .defaultHigh),

			expandButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -resourceEdgeInsets.right),
			expandButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -resourceEdgeInsets.bottom),

			shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			shadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			shadowView.heightAnchor.constraint(equalToConstant: 10),

			separatorLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
		])

		collapsedConstraint?.isActive = isCollapsed
	}

	weak var collectionViewController: CollectionViewController?
	var collectionItemRef: CollectionViewController.ItemRef?

	var isCollapsed : Bool = true

	func openClose() {
		if let collapsedConstraint = collapsedConstraint {
			isCollapsed = !isCollapsed

			expandButton.setImage(isCollapsed ? expandItemImage! : collapseItemImage!, for: .normal)

			collapsedConstraint.isActive = isCollapsed
		}

		if let collectionViewController = collectionViewController, let collectionItemRef = collectionItemRef {
			collectionViewController.performDataSourceUpdate(with: { updateDone in
				collectionViewController.collectionViewDataSource.requestReconfigurationOfItems([collectionItemRef], animated: false)
				updateDone()
			})
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		if let height = resourceView?.frame.size.height {
			if (height + resourceEdgeInsets.top + resourceEdgeInsets.bottom)  > collapsedHeight {
				expandButton.isHidden = false
				shadowView.isHidden = false
			} else {
				expandButton.isHidden = true
				shadowView.isHidden = true
			}
		}
	}
}

extension ExpandableResourceCell {
	static func registerCellProvider() {
		let itemListCellRegistration = UICollectionView.CellRegistration<ExpandableResourceCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let textResource = item as? OCResource {
					cell.resource = textResource
					cell.collectionViewController = cellConfiguration.hostViewController
					cell.collectionItemRef = collectionItemRef
				}
			})
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .textResource, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			return collectionView.dequeueConfiguredReusableCell(using: itemListCellRegistration, for: indexPath, item: itemRef)
		}))
	}

}

extension ThemeCSSSelector {
	static let expandable = ThemeCSSSelector(rawValue: "expandable")
}
