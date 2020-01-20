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
import StoreKit

class ReleaseNotesHostViewController: UIViewController {

	// MARK: - Constants
	private let cornerRadius : CGFloat = 8.0
	private let padding : CGFloat = 20.0
	private let smallPadding : CGFloat = 10.0
	private let buttonHeight : CGFloat = 44.0
	private let headerHeight : CGFloat = 60.0

	// MARK: - Instance Variables
	var titleLabel = UILabel()
	var proceedButton = ThemeButton()
	var footerButton = UIButton()

	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self)

		ReleaseNotesDatasource.setUserPreferenceValue(NSString(utf8String: VendorServices.shared.appVersion), forClassSettingsKey: .lastSeenReleaseNotesVersion)

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
		titleLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
		titleLabel.adjustsFontForContentSizeCategory = true
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
			proceedButton.translatesAutoresizingMaskIntoConstraints = false
			proceedButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
			bottomView.addSubview(proceedButton)

			footerButton.setTitle("Thank you for using ownCloud.\nIf you like our App, please leave an AppStore review.\n❤️".localized, for: .normal)
			footerButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
			footerButton.titleLabel?.adjustsFontForContentSizeCategory = true
			footerButton.titleLabel?.numberOfLines = 0
			footerButton.titleLabel?.textAlignment = .center
			footerButton.translatesAutoresizingMaskIntoConstraints = false
			footerButton.addTarget(self, action: #selector(rateApp), for: .touchUpInside)
			bottomView.addSubview(footerButton)

			NSLayoutConstraint.activate([
				footerButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: padding),
				footerButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: padding * -1),
				footerButton.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: smallPadding),
				footerButton.bottomAnchor.constraint(equalTo: proceedButton.topAnchor, constant: padding * -1)
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

	@objc func rateApp() {
		SKStoreReviewController.requestReview()
	}
}

// MARK: - Themeable implementation
extension ReleaseNotesHostViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

		self.view.backgroundColor = collection.tableBackgroundColor
		titleLabel.applyThemeCollection(collection, itemStyle: .logo)
		proceedButton.backgroundColor = collection.neutralColors.normal.background
		proceedButton.setTitleColor(collection.neutralColors.normal.foreground, for: .normal)
		footerButton.titleLabel?.textColor = collection.tableRowColors.labelColor
	}
}

class ReleaseNotesDatasource : NSObject, OCClassSettingsUserPreferencesSupport {

	var shouldShowReleaseNotes: Bool {
		if let lastSeenReleaseNotesVersion = self.classSetting(forOCClassSettingsKey: .lastSeenReleaseNotesVersion) as? String {

			if lastSeenReleaseNotesVersion.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedDescending || lastSeenReleaseNotesVersion.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedSame {
				return false
			}

			if let path = Bundle.main.path(forResource: "ReleaseNotes", ofType: "plist"), let releaseNotesValues = NSDictionary(contentsOfFile: path), let versionsValues = releaseNotesValues["Versions"] as? NSArray {

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

			return false
		} else if self.classSetting(forOCClassSettingsKey: .lastSeenAppVersion) != nil {
			if self.classSetting(forOCClassSettingsKey: .lastSeenAppVersion) as? String != VendorServices.shared.appVersion {
				   return true
			}
			return false
		} else if VendorServices.classSetting(forOCClassSettingsKey: .isBetaBuild) != nil {
			// Fallback, if app was previously installed, but user defaults key not exists. Key '.isBetaBuild' exists since version 1.0.0
			return true
		}

		return false
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
	 // Available since version 1.3.0
	static let lastSeenReleaseNotesVersion = OCClassSettingsKey("lastSeenReleaseNotesVersion")
	static let lastSeenAppVersion = OCClassSettingsKey("lastSeenAppVersion")
}

extension ReleaseNotesDatasource : OCClassSettingsSupport {
	static let classSettingsIdentifier : OCClassSettingsIdentifier = .app

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .app {
			return nil
		}

		return nil
	}
}
