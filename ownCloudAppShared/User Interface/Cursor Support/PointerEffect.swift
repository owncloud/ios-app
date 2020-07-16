//
//  PointerEffect.swift
//  ownCloud
//
//  Created by Matthias Hühne on 26.03.20.
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

public enum PointerEffectStyle : Int {
	case highlight
	case hover
	case hoverScaled
}

public class PointerEffect : NSObject, UIPointerInteractionDelegate {
	public static func install(on view: UIView, effectStyle: PointerEffectStyle) {
		if #available(iOS 13.4, *) {
			let effect = PointerEffect(for: view, effectStyle: effectStyle)

			objc_setAssociatedObject(view, &effect.objcAssociationHandle, effect, .OBJC_ASSOCIATION_RETAIN)
		}
	}

	private var objcAssociationHandle = 1
	private var effectStyle : PointerEffectStyle

	init(for view: UIView, effectStyle: PointerEffectStyle) {
		self.effectStyle = effectStyle
		super.init()

		if #available(iOS 13.4, *) {
			customPointerInteraction(on: view, pointerInteractionDelegate: self)
		}
	}

	// MARK: - UIPointerInteractionDelegate
	@available(iOS 13.4, *)
	private func customPointerInteraction(on view: UIView, pointerInteractionDelegate: UIPointerInteractionDelegate) {
		let pointerInteraction = UIPointerInteraction(delegate: pointerInteractionDelegate)
		view.addInteraction(pointerInteraction)
	}

	@available(iOS 13.4, *)
	private func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
		var pointerStyle: UIPointerStyle?

		if let interactionView = interaction.view {
			let targetedPreview = UITargetedPreview(view: interactionView)

			switch effectStyle {
			case .highlight:
				pointerStyle = UIPointerStyle(effect: UIPointerEffect.highlight(targetedPreview))
			case .hover:
				pointerStyle = UIPointerStyle(effect: UIPointerEffect.hover(targetedPreview, preferredTintMode: .overlay, prefersShadow: false, prefersScaledContent: false))
			case .hoverScaled:
				pointerStyle = UIPointerStyle(effect: UIPointerEffect.hover(targetedPreview, preferredTintMode: .overlay, prefersShadow: false, prefersScaledContent: true))
			}
		}
		return pointerStyle
	}
}
