//
//  LicenseInAppPurchaseFeatureView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 15.01.20.
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
import ownCloudApp
import ownCloudAppShared

class LicenseInAppPurchaseFeatureView: UIView, Themeable {
	var feature: OCLicenseFeature
	var environment: OCLicenseEnvironment
	weak var baseViewController: UIViewController?

	private var stateObservation : NSKeyValueObservation?

	init(with feature: OCLicenseFeature, in environment: OCLicenseEnvironment, baseViewController: UIViewController?) {
		self.feature = feature
		self.environment = environment
		self.baseViewController = baseViewController

		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false

		buildView()

		OCLicenseManager.shared.observeProducts(nil, features: [feature.identifier], in: environment, withOwner: self) { [weak self] (_, _, status) in
			guard let button = self?.purchaseButton else { return }

			switch status {
				case .unknown, .denied, .expired:
					button.setTitle("Unlock".localized, for: .normal)
					button.isEnabled = true

				case .granted:
					button.setTitle("Unlocked".localized, for: .normal)
					button.isEnabled = false
			}

			button.invalidateIntrinsicContentSize()
		}

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	var titleLabel : UILabel?
	var descriptionLabel : UILabel?

	var purchaseButton : LicenseOfferButton?

	private let titleLabelSize : CGFloat = 20
	private let descriptionLabelSize : CGFloat = 17

	func buildView() {
		titleLabel = UILabel()
		descriptionLabel = UILabel()

		guard let titleLabel = titleLabel else { return }
		guard let descriptionLabel = descriptionLabel else { return }

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = UIFont.systemFont(ofSize: self.titleLabelSize, weight: .semibold)
		descriptionLabel.font = UIFont.systemFont(ofSize: self.descriptionLabelSize)

		descriptionLabel.numberOfLines = 0

		titleLabel.text = feature.localizedName ?? feature.identifier.rawValue
		descriptionLabel.text = feature.localizedDescription ?? ""

		self.addSubview(titleLabel)
		self.addSubview(descriptionLabel)

		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		self.setContentCompressionResistancePriority(.required, for: .vertical)

		var constraints = [
			titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
			titleLabel.topAnchor.constraint(equalTo: self.topAnchor),

			descriptionLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
			descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5)
		]

		purchaseButton = LicenseOfferButton(purchaseButtonWithTitle: "", target: self, action: #selector(takeOffer))
		guard let purchaseButton = purchaseButton else { return }

		self.addSubview(purchaseButton)

		constraints.append(contentsOf: [
			purchaseButton.rightAnchor.constraint(equalTo: self.rightAnchor),
			purchaseButton.topAnchor.constraint(equalTo: self.topAnchor),

			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: purchaseButton.leftAnchor, constant: -10),
			descriptionLabel.rightAnchor.constraint(lessThanOrEqualTo: purchaseButton.leftAnchor, constant: -10),
			descriptionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])

		NSLayoutConstraint.activate(constraints)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		titleLabel?.applyThemeCollection(collection)
		descriptionLabel?.applyThemeCollection(collection)
		purchaseButton?.applyThemeCollection(collection, itemStyle: .purchase)
	}

	@objc func takeOffer() {
		let offersViewController = LicenseOffersViewController(withFeature: feature.identifier, in: environment)

		baseViewController?.present(asCard: MoreViewController(header: offersViewController.cardHeaderView!, viewController: offersViewController), animated: true)
	}
}
