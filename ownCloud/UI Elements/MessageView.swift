//
//  MessageView.swift
//  ownCloud
//
//  Created by Matthias Hühne on 23.04.19.
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

class MessageView: UIView {

	var masterView : UIView
	var messageView : UIView?
	var messageContainerView : UIView?
	var messageImageView : VectorImageView?
	var messageTitleLabel : UILabel?
	var messageMessageLabel : UILabel?
	var messageThemeApplierToken : ThemeApplierToken?
	var composeViewBottomConstraint: NSLayoutConstraint!
	var keyboardHeight : CGFloat = 0

	init(add to: UIView) {
		masterView = to
		super.init(frame: to.frame)

		// Observe keyboard change
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	required init?(coder aDecoder: NSCoder) {

		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}
	}

	func message(show: Bool, imageName : String? = nil, title : String? = nil, message : String? = nil) {
		if !show {
			if messageView?.superview != nil {
				messageView?.removeFromSuperview()
			}
			if !show {
				return
			}
		}

		if messageView == nil {
			var rootView : UIView
			var containerView : UIView
			var imageView : VectorImageView
			var titleLabel : UILabel
			var messageLabel : UILabel

			rootView = UIView()
			rootView.translatesAutoresizingMaskIntoConstraints = false

			containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			imageView = VectorImageView()
			imageView.translatesAutoresizingMaskIntoConstraints = false

			titleLabel = UILabel()
			titleLabel.translatesAutoresizingMaskIntoConstraints = false

			messageLabel = UILabel()
			messageLabel.translatesAutoresizingMaskIntoConstraints = false
			messageLabel.numberOfLines = 0
			messageLabel.textAlignment = .center

			containerView.addSubview(imageView)
			containerView.addSubview(titleLabel)
			containerView.addSubview(messageLabel)

			containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]-(20)-[titleLabel]-[messageLabel]|",
										    options: NSLayoutConstraint.FormatOptions(rawValue: 0),
										    metrics: nil,
										    views: ["imageView" : imageView, "titleLabel" : titleLabel, "messageLabel" : messageLabel])
			)

			rootView.addSubview(containerView)

			NSLayoutConstraint.activate([
				imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				imageView.widthAnchor.constraint(equalToConstant: 96),
				imageView.heightAnchor.constraint(equalToConstant: 96),

				titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
				titleLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor),

				messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				messageLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
				messageLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor),

				containerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
				containerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),

				containerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: 20),
				containerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -20),
				containerView.topAnchor.constraint(greaterThanOrEqualTo: rootView.topAnchor, constant: 20),
				containerView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -20)
			])

			messageView = rootView
			messageContainerView = containerView
			messageImageView = imageView
			messageTitleLabel = titleLabel
			messageMessageLabel = messageLabel

			messageThemeApplierToken = Theme.shared.add(applier: { [weak self] (_, collection, _) in
				self?.messageView?.backgroundColor = collection.tableBackgroundColor

				self?.messageTitleLabel?.applyThemeCollection(collection, itemStyle: .bigTitle)
				self?.messageMessageLabel?.applyThemeCollection(collection, itemStyle: .bigMessage)
			})
		}

		if messageView?.superview == nil {
			if let rootView = self.messageView, let containerView = self.messageContainerView {
				containerView.alpha = 0
				containerView.transform = CGAffineTransform(translationX: 0, y: 15)

				rootView.alpha = 0

				self.masterView.addSubview(rootView)

				self.composeViewBottomConstraint = rootView.bottomAnchor.constraint(equalTo: self.masterView.safeAreaLayoutGuide.bottomAnchor)
				if keyboardHeight > 0 {
					self.composeViewBottomConstraint.constant = self.masterView.safeAreaInsets.bottom - keyboardHeight
				}

				NSLayoutConstraint.activate([
					rootView.leftAnchor.constraint(equalTo: self.masterView.safeAreaLayoutGuide.leftAnchor),
					rootView.rightAnchor.constraint(equalTo: self.masterView.safeAreaLayoutGuide.rightAnchor),
					rootView.topAnchor.constraint(equalTo: self.masterView.safeAreaLayoutGuide.topAnchor),
					self.composeViewBottomConstraint
				])

				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
					rootView.alpha = 1
				}, completion: { (_) in
					UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
						containerView.alpha = 1
						containerView.transform = CGAffineTransform.identity
					})
				})
			}
		}

		if imageName != nil {
			messageImageView?.vectorImage = Theme.shared.tvgImage(for: imageName!)
		}
		if title != nil {
			messageTitleLabel?.text = title!
		}
		if message != nil {
			messageMessageLabel?.text = message!
		}
	}

	@objc func keyboardWillShow(notification: Notification) {
		let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
		keyboardHeight = keyboardSize?.height ?? 0

		if self.composeViewBottomConstraint != nil {
			self.composeViewBottomConstraint.constant = self.masterView.safeAreaInsets.bottom - keyboardHeight

			UIView.animate(withDuration: 0.5) {
				self.masterView.layoutIfNeeded()
			}
		}
	}

	@objc func keyboardWillHide(notification: Notification) {
		if self.composeViewBottomConstraint != nil {
			self.composeViewBottomConstraint.constant =  0

			UIView.animate(withDuration: 0.5) {
				self.masterView.layoutIfNeeded()
			}
		}
	}

}
