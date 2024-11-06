//
//  UIViewController+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 23.01.2019.
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

public extension UIViewController {

	var topMostViewController: UIViewController {

		if let presented = self.presentedViewController, presented.isBeingDismissed == false {
			 return presented.topMostViewController
		 }

		 if let navigation = self as? UINavigationController {
			 return navigation.visibleViewController?.topMostViewController ?? navigation
		 }

		 if let tab = self as? UITabBarController {
			 return tab.selectedViewController?.topMostViewController ?? tab
		 }

		 return self
	 }

	@objc @discardableResult func openURL(_ url: URL) -> Bool {
		var responder: UIResponder? = self.navigationController
		while responder != nil {
			if let application = responder as? UIApplication {
				return application.perform(#selector(openURL(_:)), with: url) != nil
			}
			responder = responder?.next
		}
		return true
	}
}

public extension UIViewController {
	func observeScreenshotEvent() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(userDidTakeScreenshot),
			name: UIApplication.userDidTakeScreenshotNotification,
			object: nil
		)
	}
	
	func stopObserveScreenshotEvent() {
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.userDidTakeScreenshotNotification,
			object: nil
		)
	}
	
	@objc private func userDidTakeScreenshot() {
		if VendorServices.shared.showScreenshotNotification {
			showScreenshotAlert()
		}
	}
	
	private func showScreenshotAlert() {
		let alert = UIAlertController(
			title: OCLocalizedString("ScreenshotNotificationTitle", nil),
			message: OCLocalizedString("ScreenshotNotificationMessage", nil),
			preferredStyle: .alert
		)
		
		alert.addAction(UIAlertAction(title: OCLocalizedString("ScreenshotNotificationButton", nil), style: .default, handler: nil))
		
		// Present the alert
		self.present(alert, animated: true, completion: nil)
	}
}

public extension UIViewController {
	func watermark(
		isWatermarkEnabled: Bool = VendorServices.shared.watermarkEnabled,
		watermarkOpacity: Int = VendorServices.shared.watermarkOpacity,
		watermarkFontSize: Int  = VendorServices.shared.watermarkFontSize,
		watermarkText: String? = VendorServices.shared.watermarkText,
		watermarkShowMail: Bool = VendorServices.shared.watermarkShowMail,
		watermarkShowDate: Bool  = VendorServices.shared.watermarkShowDate,
		username: String?,
		userMail: String?
	){
		let watermark = Watermark(
			isWatermarkEnabled: isWatermarkEnabled,
			watermarkOpacity: watermarkOpacity,
			watermarkFontSize: watermarkFontSize,
			watermarkText: watermarkText,
			watermarkShowMail: watermarkShowMail,
			watermarkShowDate: watermarkShowDate,
			username: username,
			userMail: userMail
		)
		view.addSubview(watermark)
		watermark.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			watermark.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			watermark.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			watermark.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			watermark.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
		])
	}
}

class Watermark: UIView {
	
	var angle: CGFloat = 45.0 {
		didSet { updateView() }
	}
	
	var isWatermarkEnabled: Bool {
		didSet { updateView() }
	}
	
	var watermarkOpacity: Int {
		didSet { updateView() }
	}
	
	var watermarkFontSize: Int {
		didSet { updateView() }
	}
	
	var watermarkText: String? {
		didSet { updateView() }
	}
	
	var watermarkShowMail: Bool {
		didSet { updateView() }
	}
	
	var watermarkShowDate: Bool {
		didSet { updateView() }
	}
	
	var username: String {
		didSet { updateView() }
	}
	
	var userMail: String? {
		didSet { updateView() }
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	init(
		isWatermarkEnabled: Bool,
		watermarkOpacity: Int,
		watermarkFontSize: Int ,
		watermarkText: String?,
		watermarkShowMail: Bool,
		watermarkShowDate: Bool ,
		username: String?,
		userMail: String?
	) {
		self.isWatermarkEnabled = isWatermarkEnabled
		self.watermarkOpacity = watermarkOpacity
		self.watermarkFontSize = watermarkFontSize
		self.watermarkText = watermarkText
		self.watermarkShowMail = watermarkShowMail
		self.watermarkShowDate = watermarkShowDate
		self.username = username ?? "Unknown User"
		self.userMail = userMail
		super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
		self.isUserInteractionEnabled = false
	}
	
    private var justUpdated = false
	override func updateConstraints() {
        // Prevent infinite loop. Not ideal, but working
		if !justUpdated {
			
			updateView()
		}
		justUpdated = false

		super.updateConstraints()
	}
	
	private func updateView() {
		self.subviews.forEach { $0.removeFromSuperview() }
	
		
		if isWatermarkEnabled == false {
			return
		}
		
		let watermarkString = createWatermarkString()
		
		let rotatedRect = calculateRotatedLabelDimensions(watermarkString: watermarkString, angle: angle)
		
		if rotatedRect.size.width == 0 || rotatedRect.size.height == 0 {
			return
		}
		
		// Calculate how many labels fit horizontally and vertically, applying mins and max
		let columns = min(max(Int(self.bounds.width / rotatedRect.size.width), 1), 10)
		let rows = min(max(Int(self.bounds.height / rotatedRect.size.height), 1), 10)
		
		// Calculate the total width and height occupied by the grid of labels
		let totalWidth = CGFloat(columns) * rotatedRect.size.width
		let totalHeight = CGFloat(rows) * rotatedRect.size.height

		
		// Calculate the offsets to evenly space out the grid of labels
		let horizontalOffset = (self.bounds.width - totalWidth) / CGFloat(columns + 1)
		let verticalOffset = (self.bounds.height - totalHeight) / CGFloat(rows + 1)
		
		let angleInRadiands = CGFloat.pi * (360 - angle) / 180
		
		for row in 0..<rows {
			for col in 0..<columns {
				let label = _watermarkLabel(
					watermarkString: watermarkString,
					watermarkFontSize: watermarkFontSize,
					watermarkOpacity: watermarkOpacity
				)
				// position the label with the offset so everything is evenly spaced out
				let xPosition = CGFloat(col) * rotatedRect.size.width + (CGFloat(col + 1) * horizontalOffset)
				let yPosition = CGFloat(row) * rotatedRect.size.height + (CGFloat(row + 1) * verticalOffset)
				label.frame = CGRect(
					x: xPosition,
					y: yPosition,
					width: rotatedRect.width,
					height: rotatedRect.height
				)
				
				// Rotate the label by the given angle
				label.transform = CGAffineTransform(rotationAngle: angleInRadiands)
				
				// Recalculate the size, so the text is not cut off
				label.sizeToFit()
				
				self.addSubview(label)
			}
		}
        
        justUpdated = true
	}
	
	private func createWatermarkString() -> String {
		let currentDateTime = Date()
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		formatter.dateStyle = .short
		let dateString = formatter.string(from: currentDateTime)

		var watermarkString: String
		if watermarkText?.isEmpty == false {
			watermarkString = watermarkText!
		} else if watermarkShowMail == false || userMail == nil {
			watermarkString = username
		} else {
			watermarkString = username + ", " + userMail!
		}
		if watermarkShowDate == true {
			watermarkString = watermarkString + ", " + dateString
		}
		return watermarkString
	}
	
	private func calculateRotatedLabelDimensions(
		watermarkString: String,
		angle: CGFloat
	) -> CGRect {
		let angleInRadiands = CGFloat.pi * (360 - angle) / 180
		
		let labelForSize = _watermarkLabel(
			watermarkString: watermarkString,
			watermarkFontSize: watermarkFontSize,
			watermarkOpacity: watermarkOpacity
		)
		
		labelForSize.sizeToFit()
		
		let originalSize = labelForSize.bounds.size
		
		let rotatedRect = CGRect(origin: .zero, size: originalSize).applying(CGAffineTransform(rotationAngle: angleInRadiands))
		return rotatedRect
	}
	
	private func _watermarkLabel(
		watermarkString: String,
		watermarkFontSize: Int,
		watermarkOpacity: Int
	) -> UILabel {
		let watermarkLabel = UILabel()
		watermarkLabel.text = watermarkString
		watermarkLabel.font = UIFont.boldSystemFont(ofSize: CGFloat(watermarkFontSize))
		watermarkLabel.textColor = UIColor.white.withAlphaComponent(CGFloat(Double(watermarkOpacity) / 100.0))
		watermarkLabel.textAlignment = .center
		watermarkLabel.translatesAutoresizingMaskIntoConstraints = false
		watermarkLabel.numberOfLines = 1;
		watermarkLabel.lineBreakMode = .byClipping
		watermarkLabel.layer.shadowColor = UIColor.black.cgColor
		watermarkLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
		watermarkLabel.layer.shadowOpacity = 1
		watermarkLabel.layer.shadowRadius = 10.0
		return watermarkLabel
	}
}
