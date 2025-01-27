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
	var text: String
	var subtext: String
	var textColor: UIColor
	var subtitleTextColor: UIColor
	var font: UIFont
	var subtitleFont: UIFont
	var angle: CGFloat
	var columnSpacing: CGFloat
	var lineSpacing: CGFloat
	var marginY: CGFloat

	init(text: String, subtext: String, angle: CGFloat = 45) {
		self.text = text
		self.subtext = subtext
		self.textColor = Theme.shared.activeCollection.css.getColor(.stroke, selectors: [.confidentialLabel], for: nil) ?? .red
		self.subtitleTextColor = Theme.shared.activeCollection.css.getColor(.stroke, selectors: [.confidentialSecondaryLabel], for: nil) ?? .red
		self.font = UIFont.systemFont(ofSize: 14)
		self.subtitleFont = UIFont.systemFont(ofSize: 8)
		self.angle = angle
		self.columnSpacing = 50
		self.lineSpacing = 40
		self.marginY = 10
	}
}

public class ConfidentialContentLayer: CALayer {
	var watermark: Watermark = .init(text: "Confidential Content", subtext: "Confidential Content") {
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
	var watermark: Watermark = .init(text: "Confidential Content", subtext: "Confidential Content") {
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
			watermark.textColor = color
		}
		if let color = collection.css.getColor(.stroke, selectors: [.confidentialSecondaryLabel], for: nil) {
			watermark.subtitleTextColor = color
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

		let textAttributes: [NSAttributedString.Key: Any] = [
			.font: watermark.font,
			.foregroundColor: watermark.textColor
		]
		let subtextAttributes: [NSAttributedString.Key: Any] = [
			.font: watermark.font,
			.foregroundColor: watermark.textColor
		]

		let textSize = watermark.text.size(withAttributes: textAttributes)
		let subtextSize = watermark.subtext.size(withAttributes: subtextAttributes)

		let stepX = textSize.width + watermark.columnSpacing
		let stepY = textSize.height + watermark.lineSpacing

		let stepSubtextX = subtextSize.width + watermark.columnSpacing
		let stepSubTextY = subtextSize.height + watermark.lineSpacing

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
				if col % 2 == 0 {
					watermark.text.draw(at: CGPoint(x: x, y: y), withAttributes: textAttributes)
					x += stepX
				} else {
					watermark.subtext.draw(at: CGPoint(x: x, y: y + (stepSubTextY / 2)), withAttributes: subtextAttributes)
					x += stepSubtextX
				}
				col += 1
			}
			y += stepY
		}

		restoreGState()

		if watermark.angle < 45.0 {
			let combinedText = "\(watermark.subtext) - \(watermark.text)"
			let combinedTextAttributes: [NSAttributedString.Key: Any] = [
				.font: watermark.subtitleFont,
				.foregroundColor: watermark.subtitleTextColor
			]
			let combinedTextSize = combinedText.size(withAttributes: combinedTextAttributes)

			var x = CGFloat(0)
			let subtextY = rect.height - combinedTextSize.height - 2
			while x < rect.width {
				combinedText.draw(at: CGPoint(x: x, y: subtextY), withAttributes: combinedTextAttributes)
				x += combinedTextSize.width + watermark.columnSpacing
			}
		}

		UIGraphicsPopContext()
	}
}

public extension UIView {
	func secureView(core: OCCore?, useLayer: Bool = false) {
		if !ConfidentialManager.shared.markConfidentialViews { return }

		let watermark = Watermark(text: core?.bookmark.user?.emailAddress ?? "Confidential View", subtext: core?.bookmark.userName ?? "Confidential View", angle: (frame.height <= 200) ? 10 : 45)

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
