//
//  BrandView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 12.10.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp

open class BrandView: UIView {
	open var showBackground: Bool = true {
		didSet {
			render()
		}
	}

	open var showLogo: Bool = true {
		didSet {
			render()
		}
	}
	open var logoMaxSize: CGSize? {
		didSet {
			render()
		}
	}
	open var fitToLogo: Bool = false {
		didSet {
			render()
		}
	}

	open var roundedCorners: Bool = true {
		didSet {
			render()
		}
	}
	open var assetSuffix: BrandingAssetSuffix? {
		didSet {
			render()
		}
	}

	public init(showBackground: Bool, showLogo: Bool, logoMaxSize: CGSize? = nil, fitToLogo: Bool = false, roundedCorners: Bool, assetSuffix: BrandingAssetSuffix? = nil) {
		super.init(frame: CGRect(x: 0, y: 0, width: 128, height: 128))

		translatesAutoresizingMaskIntoConstraints = false

		self.showBackground = showBackground

		self.showLogo = showLogo
		self.logoMaxSize = logoMaxSize
		self.fitToLogo = fitToLogo

		self.roundedCorners = roundedCorners
		self.assetSuffix = assetSuffix

		self.cssSelector = .brand

		render()
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Views
	private var backgroundColorView: ThemeCSSView?
	private var backgroundImageView: UIImageView?
	private var logoImageView: UIImageView?

	func render() {
		// Create and add background views
		backgroundColorView?.removeFromSuperview()
		backgroundColorView = nil

		backgroundImageView?.removeFromSuperview()
		backgroundImageView = nil

		if showBackground {
			// Add background
			if let backgroundImage = Branding.shared.brandedImageNamed(.brandBackground, assetSuffix: assetSuffix) ?? Branding.shared.brandedImageNamed(.legacyBrandBackground, assetSuffix: assetSuffix) {
				// Add background image
				backgroundImageView = UIImageView(image: backgroundImage)
				backgroundImageView?.translatesAutoresizingMaskIntoConstraints = false
				backgroundImageView?.contentMode = .scaleAspectFill
				backgroundImageView?.cssSelector = .background
				backgroundImageView?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 700), for: .horizontal) // make background image view have a smaller compression resistance than the parent view (defaults to 750), in order not to establish that the background image width does not determine the superview's width

				embed(toFillWith: backgroundImageView!)
			} else {
				// Add background color
				backgroundColorView = ThemeCSSView(withSelectors: [.background])
				backgroundColorView?.translatesAutoresizingMaskIntoConstraints = false
				embed(toFillWith: backgroundColorView!)
			}

			// Apply rounded corners
			if roundedCorners {
				let cornerRadius: CGFloat = 10

				backgroundColorView?.layer.cornerRadius = cornerRadius
				backgroundColorView?.clipsToBounds = true

				backgroundImageView?.layer.cornerRadius = cornerRadius
				backgroundImageView?.clipsToBounds = true

				layer.cornerRadius = cornerRadius
				clipsToBounds = true
			}
		}

		// Logo image view
		logoImageView?.removeFromSuperview()
		logoImageView = nil

		if showLogo {
			if let logoImage = Branding.shared.brandedImageNamed(.brandLogo, assetSuffix: assetSuffix) ?? Branding.shared.brandedImageNamed(.legacyBrandLogo, assetSuffix: assetSuffix) {
				logoImageView = UIImageView(image: logoImage)
				logoImageView?.translatesAutoresizingMaskIntoConstraints = false
				logoImageView?.contentMode = .scaleAspectFit
				logoImageView?.accessibilityLabel = VendorServices.shared.appName
				logoImageView?.cssSelector = .icon

				if let logoImageView {
					// Apply aspect ratio maximum size
					if let logoMaxSize {
						let logoImageSize = UIImage.sizeThatFits(logoImage.size, into: logoMaxSize)

						NSLayoutConstraint.activate([
							logoImageView.widthAnchor.constraint(equalToConstant: logoImageSize.width),
							logoImageView.heightAnchor.constraint(equalToConstant: logoImageSize.height)
						])
					}

					if fitToLogo {
						embed(toFillWith: logoImageView)
					} else {
						addSubview(logoImageView)
						NSLayoutConstraint.activate([
							logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
							logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
						])
					}
				}
			}
		}
	}
}

extension BrandView: DataItemSelectionInteraction {
	public func allowSelection(in viewController: UIViewController?, section: CollectionViewSection?, with context: ClientContext?) -> Bool {
		return false
	}
}
