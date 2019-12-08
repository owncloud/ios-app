//
//  ReleaseNotesHostViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 04.12.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class ReleaseNotesHostViewController: UIViewController {

	// MARK: - Constants
	private let cornerRadius : CGFloat = 8.0
	private let padding : CGFloat = 20.0
	private let smallPadding : CGFloat = 10.0
	private let buttonHeight : CGFloat = 44.0
	private let headerHeight : CGFloat = 60.0

	// MARK: - Instance Variables
	var titleLabel = UILabel()
	var proceedButton = UIButton(type: .roundedRect)
	var footerLabel = UILabel()

	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self)

		VendorServices.setUserPreferenceValue(NSString(utf8String: VendorServices.shared.appVersion), forClassSettingsKey: .lastSeenReleaseNotesVersion)

		let headerView = UIView()
		headerView.backgroundColor = .clear
		headerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(headerView)
		NSLayoutConstraint.activate([
			headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			headerView.heightAnchor.constraint(equalToConstant: headerHeight)
		])

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)

		titleLabel.text = "New in ownCloud".localized
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 0
		titleLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.5, weight: .bold)
		headerView.addSubview(titleLabel)

		NSLayoutConstraint.activate([
			titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: headerView.safeAreaLayoutGuide.leftAnchor, constant: padding),
			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: headerView.safeAreaLayoutGuide.rightAnchor, constant: padding * -1),
			titleLabel.centerXAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.centerXAnchor),

			titleLabel.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: padding)
		])

		let releaseNotesController = ReleaseNotesTableViewController(style: .plain)
		if let containerView = releaseNotesController.view {
			containerView.backgroundColor = .clear
			containerView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(containerView)

			let bottomView = UIView()
			bottomView.backgroundColor = .clear
			bottomView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(bottomView)
			NSLayoutConstraint.activate([
				bottomView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				bottomView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				bottomView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
				bottomView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
			])

			proceedButton.setTitle("Proceed".localized, for: .normal)
			proceedButton.layer.cornerRadius = cornerRadius
			proceedButton.translatesAutoresizingMaskIntoConstraints = false
			proceedButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
			bottomView.addSubview(proceedButton)

			footerLabel.textAlignment = .center
			footerLabel.translatesAutoresizingMaskIntoConstraints = false
			footerLabel.text = "Thank you for using ownCloud.\nIf you like our App, please leave an AppStore review.\n❤️".localized
			footerLabel.numberOfLines = 0
			footerLabel.font = UIFont.systemFont(ofSize: 14.0)
			bottomView.addSubview(footerLabel)

			NSLayoutConstraint.activate([
				footerLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: padding),
				footerLabel.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: padding * -1),
				footerLabel.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: smallPadding),
				footerLabel.bottomAnchor.constraint(equalTo: proceedButton.topAnchor, constant: padding * -1)
			])

			NSLayoutConstraint.activate([
				proceedButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: padding),
				proceedButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: padding * -1),
				proceedButton.heightAnchor.constraint(equalToConstant: buttonHeight),
				proceedButton.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor, constant: smallPadding * -1)
			])

			NSLayoutConstraint.activate([
				containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				containerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
				containerView.bottomAnchor.constraint(equalTo: bottomView.topAnchor)
			])
		}
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	@objc func dismissView() {
		self.dismiss(animated: true, completion: nil)
	}
}

// MARK: - Themeable implementation
extension ReleaseNotesHostViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

		self.view.backgroundColor = collection.tableBackgroundColor
		titleLabel.applyThemeCollection(collection, itemStyle: .logo)
		proceedButton.backgroundColor = collection.neutralColors.normal.background
		proceedButton.setTitleColor(collection.neutralColors.normal.foreground, for: .normal)
		footerLabel.textColor = collection.tableRowColors.labelColor
	}
}

class ReleaseNotesDatasource : NSObject, OCClassSettingsUserPreferencesSupport {

	var shouldShowReleaseNotes: Bool {
		if let lastSeenReleaseNotesVersion = self.classSetting(forOCClassSettingsKey: .lastSeenReleaseNotesVersion) as? String {

			if lastSeenReleaseNotesVersion.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedDescending || lastSeenReleaseNotesVersion.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedSame {
				return false
			}

			if let path = Bundle.main.path(forResource: "ReleaseNotes", ofType: "plist") {
				if let releaseNotesValues = NSDictionary(contentsOfFile: path), let versionsValues = releaseNotesValues["Versions"] as? NSArray {

					let relevantReleaseNotes = versionsValues.filter {
						if let version = ($0 as AnyObject)["Version"] as? String, version.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedDescending {
							return false
						}

						return true
					}

					if relevantReleaseNotes.count > 0 {
						return true
					}
				}
			}

			return false
		}

		return true
	}

	func releaseNotes(for version: String) -> [[String:Any]]? {
		if let path = Bundle.main.path(forResource: "ReleaseNotes", ofType: "plist") {
			if let releaseNotesValues = NSDictionary(contentsOfFile: path), let versionsValues = releaseNotesValues["Versions"] as? NSArray {

				let relevantReleaseNotes = versionsValues.filter {
					if let version = ($0 as AnyObject)["Version"] as? String, version.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedAscending {
						return false
					}

					return true
				}

				return relevantReleaseNotes as? [[String:Any]]
			}
		}

		return nil
	}
}

extension OCClassSettingsKey {
	static let lastSeenReleaseNotesVersion = OCClassSettingsKey("lastSeenReleaseNotesVersionTest")
}

extension ReleaseNotesDatasource : OCClassSettingsSupport {
	static let classSettingsIdentifier : OCClassSettingsIdentifier = .app

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .app {
			return [ .lastSeenReleaseNotesVersion : true]
		}

		return nil
	}
}
