//
//  ConfidentialContentView.swift
//  ownCloud
//
//  Created by Matthias Hühne on 09.12.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import ownCloudSDK
import ownCloudApp

public struct Watermark {
	var texts: [String]
	var textColor: UIColor {
		get {
			if let textColor = ConfidentialManager.shared.textColor, let color = String(textColor).colorFromHex?.withAlphaComponent(ConfidentialManager.shared.textOpacity) {
				return color
			} else {
				if let color = Theme.shared.activeCollection.css.getColor(.stroke, selectors: [.confidentialLabel], for: nil) {
					return color.withAlphaComponent(ConfidentialManager.shared.textOpacity)
				}
			}
			return .red.withAlphaComponent(ConfidentialManager.shared.textOpacity)
		}
		set {
		}
	}
	var font: UIFont
	var angle: CGFloat
	var columnSpacing: CGFloat
	var lineSpacing: CGFloat
	var marginY: CGFloat

	init(texts: [String], angle: CGFloat = 45) {
		self.texts = texts
		self.font = UIFont.systemFont(ofSize: 14)
		self.angle = angle
		self.columnSpacing = 10
		self.lineSpacing = ConfidentialManager.shared.lineSpacing
		self.marginY = 10
	}
}

public class ConfidentialContentLayer: CALayer {
	var watermark: Watermark = .init(texts: ["Confidential Content"]) {
		didSet {
			setNeedsDisplay()
		}
	}

	init(watermark: Watermark) {
		super.init()
		self.watermark = watermark
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override var frame: CGRect {
		didSet {
			setNeedsDisplay()
		}
	}

	public override func draw(in ctx: CGContext) {
		ctx.draw(watermark: watermark, in: bounds)
	}

	public override func layoutIfNeeded() {
		if let superlayer {
			frame = superlayer.bounds
		}
	}
}

public class ConfidentialContentView: UIView, Themeable {
	var watermark: Watermark = .init(texts: ["Confidential Content"]) {
		didSet {
			setNeedsDisplay()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupViewAndObservers()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupViewAndObservers()
	}

	deinit {
		Theme.shared.unregister(client: self)
		NotificationCenter.default.removeObserver(self)
	}

	private func setupViewAndObservers() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleOrientationChange),
			name: UIDevice.orientationDidChangeNotification,
			object: nil
		)

		backgroundColor = .clear

		Theme.shared.register(client: self, applyImmediately: true)
	}

	@objc private func handleOrientationChange() {
		setNeedsDisplay()
	}

	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, with: event)
		return view == self ? nil : view // Allow touches to pass through
	}

	public override func draw(_ rect: CGRect) {
		guard ConfidentialManager.shared.markConfidentialViews, let context = UIGraphicsGetCurrentContext() else { return }
		context.draw(watermark: watermark, in: rect)
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if let color = collection.css.getColor(.stroke, selectors: [.confidentialLabel], for: nil) {
			watermark.textColor = color.withAlphaComponent(ConfidentialManager.shared.textOpacity)
		}
		setNeedsDisplay()
	}
}

public extension CGContext {
	func draw(watermark: Watermark, in rect: CGRect) {
		UIGraphicsPushContext(self)

		saveGState()

		let radians = watermark.angle * .pi / 180
		rotate(by: radians)
		
		let text = watermark.texts.joined(separator: ", ")

		let textAttributes: [NSAttributedString.Key: Any] = [
			.font: watermark.font,
			.foregroundColor: watermark.textColor
		]

		let textSize = text.size(withAttributes: textAttributes)

		let stepX = textSize.width + watermark.columnSpacing
		let stepY = textSize.height + watermark.lineSpacing

		let rotatedDiagonal = sqrt(rect.width * rect.width + rect.height * rect.height)

		let startX = -rotatedDiagonal
		let startY = -rotatedDiagonal + watermark.marginY
		let endX = rotatedDiagonal
		let endY = rotatedDiagonal - watermark.marginY

		var y = startY
		while y <= endY {
			var x = startX
			var col = 0
			while x <= endX {
				text.draw(at: CGPoint(x: x, y: y), withAttributes: textAttributes)
				x += stepX
			}
			y += stepY
		}

		restoreGState()

		UIGraphicsPopContext()
	}
}

public extension UIView {
	func secureView(core: OCCore?, useLayer: Bool = false) {
		if !ConfidentialManager.shared.markConfidentialViews { return }

		var texts: [String] = []
		if ConfidentialManager.shared.showUserEmail, let email = core?.bookmark.user?.emailAddress {
			texts.append(email)
		}
		if ConfidentialManager.shared.showUserID, let userID = core?.bookmark.user?.userIdentifier {
			texts.append(userID)
		}
		if let text = ConfidentialManager.shared.customText as? String {
			texts.append(text)
		}
		if ConfidentialManager.shared.showTimestamp {
			texts.append(Date().formatted(.dateTime))
		}
		
		let watermark = Watermark(texts: texts, angle: (frame.height <= 200) ? -10 : -45)

		if useLayer {
			let overlayLayer = ConfidentialContentLayer(watermark: watermark)
			overlayLayer.frame = layer.bounds
			layer.addSublayer(overlayLayer)
		} else {
			let overlayView = ConfidentialContentView()
			overlayView.watermark = watermark
			overlayView.backgroundColor = .clear
			overlayView.translatesAutoresizingMaskIntoConstraints = false
			embed(toFillWith: overlayView)
		}
	}

	var withScreenshotProtection: UIView {
		if ConfidentialManager.shared.allowScreenshots {
			return self
		}

		let secureContainerView = SecureTextField().secureContainerView
		secureContainerView.embed(toFillWith: self)
		return secureContainerView
	}
}
