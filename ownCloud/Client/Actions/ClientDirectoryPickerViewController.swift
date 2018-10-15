//
//  ClientDirectoryPickerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 22/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ClientDirectoryPickerViewController: ClientQueryViewController {

	private var selectButton: ThemeButton
	private var completion: (OCItem) -> Void
	private var cancelBarButton: UIBarButtonItem!

	private static var directoryFilterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
		if let item = item {
			if item.type == .collection {return true}
		}
		return false
	}

	init(core inCore: OCCore, path: String, completion: @escaping (OCItem) -> Void) {
		selectButton = ThemeButton()
		self.completion = completion
		let query = OCQuery.init(forPath: path)
		super.init(core: inCore, query: query!)

		self.query?.addFilter(OCQueryFilter.init(handler: ClientDirectoryPickerViewController.directoryFilterHandler), withIdentifier: "directory-filter")

		Theme.shared.register(client: self)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.bringSubview(toFront: selectButton)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Select Button setup
		selectButton.translatesAutoresizingMaskIntoConstraints = false
		tableView.addSubview(selectButton)

		NSLayoutConstraint.activate([
			selectButton.leftAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leftAnchor),
			selectButton.rightAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.rightAnchor),
			selectButton.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor),
			selectButton.heightAnchor.constraint(equalToConstant: 44)
		])

		cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonPressed))
		navigationItem.rightBarButtonItem = cancelBarButton

		selectButton.setTitle("Move Here".localized, for: .normal)
		selectButton.addTarget(self, action: #selector(selectButtonPressed), for: .touchUpInside)
 		tableView.tableFooterView = UIView()
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let items = items else {
			return
		}

		let item = items[indexPath.row]

		guard item.type == OCItemType.collection else {
			return
		}

		self.navigationController?.pushViewController(ClientDirectoryPickerViewController(core: core!, path: item.path, completion: completion), animated: true)
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return nil
	}

	@objc private func cancelBarButtonPressed() {
		self.dismiss(animated: true)
	}

	@objc private func selectButtonPressed() {
		guard let query = query else {
			return
		}

		self.dismiss(animated: true, completion: {
			self.completion(query.rootItem)
		})
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
		self.selectButton.applyThemeCollection(collection)
	}
}
