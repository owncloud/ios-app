//
//  RoundedTableViewCell.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 07/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class RoundedTableViewCell: UITableViewCell {

	private var cornerWidth: CGFloat
	private var cornerHeight: CGFloat
	private var lateralInset: CGFloat

	init(lateralInset: CGFloat, cornerWidth: CGFloat, cornerHeight: CGFloat) {
		self.cornerWidth = cornerWidth
		self.lateralInset = lateralInset
		self.cornerHeight = cornerHeight
		super.init(style:.default, reuseIdentifier: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let maskLayer = CAShapeLayer()
		let width = self.bounds.width - ((lateralInset * 2) + (safeAreaInsets.left * 2))
		let originX = lateralInset + safeAreaInsets.left
		let maskRect = CGRect(x: originY, y: 0, width: width , height: self.bounds.height)
		let path = CGPath(roundedRect: maskRect, cornerWidth: cornerWidth, cornerHeight: cornerHeight, transform: nil)
		maskLayer.path = path
		self.layer.mask = maskLayer
		self.layer.masksToBounds = true
		self.clipsToBounds = true
	}
}
