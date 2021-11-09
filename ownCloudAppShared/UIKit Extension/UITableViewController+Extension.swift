//
//  UITableViewController+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 26.02.19.
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

public extension UITableViewController {

	func addThemableBackgroundView() {
		// UITableView background view is nil for default. Set a UIView with clear color to can insert a subview above
		let backgroundView = UIView.init(frame: self.tableView.frame)
		backgroundView.backgroundColor = UIColor.clear
		self.tableView.backgroundView = backgroundView

		// This view is needed to stop flickering when scrolling (white line between UINavigationBar and UITableView header
		let coloredView = ThemeableColoredView(frame: CGRect(x: 0, y: -self.view.frame.size.height, width: self.view.frame.size.width, height: self.view.frame.size.height + 1))
		coloredView.translatesAutoresizingMaskIntoConstraints = false

		self.tableView.insertSubview(coloredView, aboveSubview: self.tableView.backgroundView!)

		NSLayoutConstraint.activate([
			coloredView.topAnchor.constraint(equalTo: self.tableView.topAnchor, constant: -self.view.frame.size.height),
			coloredView.leftAnchor.constraint(equalTo: self.tableView.leftAnchor),
			coloredView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor),
			coloredView.heightAnchor.constraint(equalToConstant: self.view.frame.size.height + 1)
			])
	}

	func colorSection(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath, borderColor: UIColor?) {
		let cornerRadius: CGFloat = 10.0
		let layer: CAShapeLayer = CAShapeLayer()
		let pathRef: CGMutablePath = CGMutablePath()

		let bounds: CGRect = cell.bounds.insetBy(dx: 0, dy: 0)

		if indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
			pathRef.addRoundedRect(in: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: .identity)
		} else if indexPath.row == 0 {
			pathRef.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
			pathRef.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.minY),
						   tangent2End: CGPoint(x: bounds.midX, y: bounds.minY),
						   radius: cornerRadius)

			pathRef.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.minY),
						   tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY),
						   radius: cornerRadius)
			pathRef.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
		} else if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
			pathRef.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
			pathRef.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.maxY),
						   tangent2End: CGPoint(x: bounds.midX, y: bounds.maxY),
						   radius: cornerRadius)

			pathRef.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.maxY),
						   tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY),
						   radius: cornerRadius)
			pathRef.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
		} else {
			pathRef.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
			pathRef.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))

			pathRef.move(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
			pathRef.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
		}

		layer.path = pathRef
		layer.strokeColor = borderColor?.cgColor ?? UIColor.lightGray.cgColor
		layer.lineWidth = 1.0
		layer.fillColor =  UIColor.clear.cgColor

		let backgroundView: UIView = UIView(frame: bounds)
		backgroundView.layer.insertSublayer(layer, at: 0)
		backgroundView.backgroundColor = .clear
		cell.backgroundView = backgroundView
	}
}
