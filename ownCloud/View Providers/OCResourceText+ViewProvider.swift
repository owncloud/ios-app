//
//  OCResourceText+ViewProvider.swift
//  ownCloud
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
import ownCloudAppShared
import Down

class ThemeableTextView : UITextView, Themeable {
	init() {
		registeredThemeable = false
		super.init(frame: .zero, textContainer: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	private var registeredThemeable : Bool

	func registerThemeable() {
		if !registeredThemeable {
			registeredThemeable = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	override var attributedText: NSAttributedString! {
		didSet {
			registerThemeable()
		}
	}

	override var text: String! {
		didSet {
			registerThemeable()
		}
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		backgroundColor = collection.tableBackgroundColor
		textColor = collection.tableRowColors.labelColor
	}
}

extension OCResourceText : OCViewProvider {
	public func provideView(for size: CGSize, in context: OCViewProviderContext?, completion completionHandler: @escaping (UIView?) -> Void) {
		var attributedText : NSAttributedString?

		if let mimeType = mimeType {
			switch mimeType {
				case "text/markdown":
					// Render mark down
					if let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) {
						let down = Down(markdownString: text)
						let styler = DownStyler()

						if let attributedString = try? down.toAttributedString(.default, styler: styler) {
							attributedText = attributedString
						}
					}

				default: break
			}
		}

		let textView = ThemeableTextView()

		textView.translatesAutoresizingMaskIntoConstraints = false

		textView.isEditable = false
		textView.isScrollEnabled = false

		if let attributedText = attributedText {
			textView.attributedText = attributedText
		} else if let text = text {
			textView.text = text
			textView.font = UIFont.preferredFont(forTextStyle: .body)
		}

		textView.setContentCompressionResistancePriority(.required, for: .vertical)

		completionHandler(textView)
	}
}
