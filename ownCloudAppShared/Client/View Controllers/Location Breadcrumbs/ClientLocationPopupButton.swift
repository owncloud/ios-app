//
//  ClientLocationPopupButton.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.10.23.
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
import ownCloudSDK

open class ClientLocationPopupButton: ThemeCSSButton {
	weak var clientContext: ClientContext?
	open var location: OCLocation? {
		didSet {
			updateButton()
		}
	}

	public init(clientContext: ClientContext? = nil, location: OCLocation? = nil, excludeLastPathComponent: Bool = true) {
		super.init(frame: .zero)
		cssSelectors = [.title]

		self.clientContext = clientContext
		self.location = location

		titleLabel?.adjustsFontForContentSizeCategory = true
		semanticContentAttribute = (effectiveUserInterfaceLayoutDirection == .leftToRight) ? .forceRightToLeft : .forceLeftToRight
		setContentHuggingPriority(.defaultHigh, for: .horizontal)
		setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
		showsMenuAsPrimaryAction = true
		translatesAutoresizingMaskIntoConstraints = false

		menu = UIMenu(title: "", children: [
			UIDeferredMenuElement.uncached({ [weak self] completion in
				var menuItems : [UIMenuElement] = []
				let breadcrumbLocation = excludeLastPathComponent ? self?.location?.parent : self?.location

				if let clientContext = self?.clientContext, let breadcrumbs = breadcrumbLocation?.breadcrumbs(in: clientContext, includeServerName: false, action: .reveal).reversed() {
					for crumbAction in breadcrumbs {
						menuItems.append(crumbAction.uiAction())
					}
				}

				completion(menuItems)
			})
		])

		updateButton()
	}

	open override func didMoveToWindow() {
		super.didMoveToWindow()

		self.updateButton()
	}

	func updateButton() {
		let title = location?.displayName(in: clientContext) ?? "-"
		let attributedTitle = AttributedString(NSAttributedString(string: title, attributes: [.font : UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .semibold)]))
		let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 0.7 * UIFont.buttonFontSize)
		let chevronBackgroundColor = Theme.shared.activeThemeCSS.getColor(.fill, selectors: [.popupButton, .icon], for: self) ?? .lightGray
		let chevronForegroundColor = Theme.shared.activeThemeCSS.getColor(.stroke, selectors: [.popupButton, .icon], for: self) ?? .tintColor
		let chevronImage = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: symbolConfiguration)?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [chevronForegroundColor, chevronBackgroundColor]))

		var buttonConfig = configuration ?? .plain()
		buttonConfig.imagePadding = 5
		buttonConfig.attributedTitle = attributedTitle
		#if swift(>=5.9) // workaround build issue on Xcode 14.2 (GitHub actions)
		buttonConfig.titleLineBreakMode = .byTruncatingMiddle
		#endif
		buttonConfig.image = chevronImage

		self.configuration = buttonConfig
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
