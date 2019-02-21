//
//  AlternativeCollectionCollectionViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 14/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

private let reuseIdentifier = "Cell"

class AlternativeCollectionCollectionViewController: UICollectionViewController {

	weak private var core: OCCore?
	private var items: [OCItem]
	private var query: OCQuery
	private var index: Int

	// MARK: - Init & deinit
	init(core: OCCore, items: [OCItem], query: OCQuery, index: Int = 0) {
		self.core = core
		self.items = items
		self.query = query
		self.index = index

		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		super.init(collectionViewLayout: layout)

		query.addObserver(self, forKeyPath: "hasChangesAvailable", options: [.new], context: nil)
	}

	deinit {
		query.removeObserver(self, forKeyPath: "hasChangesAvailable")
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cell classes
        self.collectionView!.register(GalleryCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		self.collectionView.isPagingEnabled = true
		self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? GalleryCollectionViewCell

		let itemToDisplay = items[indexPath.row]
		let mimeType = itemToDisplay.mimeType!

		let viewController = self.selectDisplayViewControllerBasedOn(mimeType: mimeType)
		let shouldDownload = viewController is (DisplayViewController & DisplayExtension) ? true : false

		var configuration: DisplayViewConfiguration
		if !shouldDownload {
			configuration = DisplayViewConfiguration(item: itemToDisplay, core: core, state: .notSupportedMimeType)
		} else {
			configuration = DisplayViewConfiguration(item: itemToDisplay, core: core, state: .hasNetworkConnection)
		}

		if cell?.item == nil {
			cell?.item = itemToDisplay
			viewController.configure(configuration)
			self.addChild(viewController)
			cell?.contentView.addSubview(viewController.view)
			viewController.didMove(toParent: self)
			viewController.present(item: itemToDisplay)
		} else {
			if cell?.item != itemToDisplay {
				cell?.item = itemToDisplay
				viewController.configure(configuration)
				self.addChild(viewController)
				cell?.contentView.addSubview(viewController.view)
				viewController.didMove(toParent: self)
				viewController.present(item: itemToDisplay)
			}
		}

        return cell!
    }

	// MARK: - Extension selection
	private func selectDisplayViewControllerBasedOn(mimeType: String) -> (DisplayViewController) {

		let locationIdentifier = OCExtensionLocationIdentifier(rawValue: mimeType)
		let location: OCExtensionLocation = OCExtensionLocation(ofType: .viewer, identifier: locationIdentifier)
		let context = OCExtensionContext(location: location, requirements: nil, preferences: nil)

		var extensions: [OCExtensionMatch]?

		do {
			try extensions = OCExtensionManager.shared.provideExtensions(for: context)
		} catch {
			return DisplayViewController()
		}

		guard let matchedExtensions = extensions else {
			return DisplayViewController()
		}

		let preferedExtension: OCExtension = matchedExtensions[0].extension

		let extensionObject = preferedExtension.provideObject(for: context)

		guard let controllerType = extensionObject as? (DisplayViewController & DisplayExtension) else {
			return DisplayViewController()
		}

		return controllerType
	}

	// MARK: - KVO observing
	// swiftlint:disable block_based_kvo
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if keyPath == "hasChangesAvailable" {
			if let newValue = change?[NSKeyValueChangeKey.newKey] as? Bool {
				print("LOG ---> newValue = \(newValue)")
			}
		}
		if (object as? OCQuery) === query, query.hasChangesAvailable {
			query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag.init(rawValue: 0)) { ( _, changeSet) in
				guard changeSet != nil else { return }
				self.items = changeSet!.queryResult
				OnMainThread {
					self.collectionView.reloadData()
				}
			}
		}
	}
	// swiftlint:enable block_based_kvo
}

extension AlternativeCollectionCollectionViewController: UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return self.view.frame.size
	}
}
