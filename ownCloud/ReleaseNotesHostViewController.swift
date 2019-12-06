//
//  ReleaseNotesHostViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 04.12.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class ReleaseNotesHostViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		self.view.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor

		let headerView = UIView()
		headerView.backgroundColor = .clear// .green
		headerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(headerView)
		NSLayoutConstraint.activate([
			headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
			headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
			headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
			headerView.heightAnchor.constraint(equalToConstant: 60.0)
		])

		let titleLabel = UILabel()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)

		titleLabel.text = "New in ownCloud".localized
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 0
		headerView.addSubview(titleLabel)
/*
		headerView.addThemeApplier({ (_, collection, _) in
			titleLabel.applyThemeCollection(collection, itemStyle: .logo)
		})*/

		titleLabel.applyThemeCollection(Theme.shared.activeCollection, itemStyle: .logo)

		titleLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.5, weight: .bold)

		NSLayoutConstraint.activate([
			titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: headerView.safeAreaLayoutGuide.leftAnchor, constant: 20),
			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: headerView.safeAreaLayoutGuide.rightAnchor, constant: -20),
			titleLabel.centerXAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.centerXAnchor),

			titleLabel.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: 20)
		])

		let releaseNotesController = ReleaseNotesTableViewController(style: .plain)
		if let containerView = releaseNotesController.view {// UIView() {
				containerView.backgroundColor = .clear// .red
			containerView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(containerView)

		let bottomView = UIView()
		bottomView.backgroundColor = .clear//.green
		bottomView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(bottomView)
		NSLayoutConstraint.activate([
			bottomView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
			bottomView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
			bottomView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
			bottomView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
		])

		let button = UIButton(type: .roundedRect)
			button.backgroundColor = Theme.shared.activeCollection.neutralColors.normal.background
			button.setTitleColor(Theme.shared.activeCollection.neutralColors.normal.foreground, for: .normal)

			button.setTitle("Proceed".localized, for: .normal)
		button.layer.cornerRadius = 8
		button.translatesAutoresizingMaskIntoConstraints = false
			button.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
		bottomView.addSubview(button)

			let label = UILabel()
			label.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
			label.textAlignment = .center
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = "Thank you for using ownCloud.\nIf you like our App, please leave an AppStore review.\n❤️".localized
			label.numberOfLines = 0
			label.font = UIFont.systemFont(ofSize: 14.0)
			bottomView.addSubview(label)

			NSLayoutConstraint.activate([
				label.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 20),
				label.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -20),
				label.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 10),
				label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -20)
			])

		NSLayoutConstraint.activate([
			button.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 20),
			button.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -20),
			button.heightAnchor.constraint(equalToConstant: 44),
			button.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: -10)
		])

	NSLayoutConstraint.activate([
		containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
		containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
		containerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
		containerView.bottomAnchor.constraint(equalTo: bottomView.topAnchor, constant: 0)
	])
	}

    }

	@objc func dismissView() {
		self.dismiss(animated: true, completion: nil)
	}

}
