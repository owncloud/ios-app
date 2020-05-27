//
//  AlertCollectionViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.05.20.
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

protocol AlertCollectionViewControllerSource : class {
	func numberOfAlert(in controller: AlertCollectionViewController) -> Int
	func alertView(for: AlertCollectionViewController, at index: Int) -> AlertView
}

class AlertCollectionViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, Themeable {
	var flowLayout : UICollectionViewFlowLayout

	var pages : [ScanPage] = [] {
		didSet {
			self.collectionView.reloadData()
		}
	}

	private let verticalPadding : CGFloat = 25
	private let horizontalPadding : CGFloat = 20

	weak var source : AlertCollectionViewControllerSource?

	init (with source: AlertCollectionViewControllerSource?) {
		flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = .horizontal
//		flowLayout.estimatedItemSize = CGSize(width: width, height: 128)
		flowLayout.sectionInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
		flowLayout.minimumInteritemSpacing = 20

		self.source = source

		super.init(collectionViewLayout: flowLayout)

		self.collectionView.alwaysBounceHorizontal = true
		self.collectionView.register(AlertCollectionViewCell.self, forCellWithReuseIdentifier: "alert-cell")

		Theme.shared.register(client: self, applyImmediately: true)

	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		flowLayout.estimatedItemSize = CGSize(width: self.view.frame.size.width - 20, height: 128)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.collectionView.backgroundColor = collection.tableBackgroundColor
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pages.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "alert-cell", for: indexPath)

		if let alertCell = cell as? AlertCollectionViewCell {
			alertCell.alertView = source?.alertView(for: self, at: indexPath.item)
		}

		return cell
	}
}
