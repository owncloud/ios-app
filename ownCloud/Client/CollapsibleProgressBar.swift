//
//  CollapsibleProgressBar.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class CollapsibleProgressBar: UIView, Themeable {
	var contentView : UIView = UIView()
	var progressView : UIProgressView = UIProgressView()
	var progressLabelView : UILabel = UILabel(frame: CGRect.zero)
	var contentViewHeight : CGFloat = 0
	var heightConstraint : NSLayoutConstraint?
	var isCollapsed : Bool = true
	var autoCollapse : Bool = true

	private var _progress : Float = 0
	var progress : Float {
		set(newProgress) {
			var displayProgress = newProgress

			_progress = newProgress

			if displayProgress < 0 {
				displayProgress = 0
				// Start pulsing
			} else {
				// Stop pulsing
			}

			if displayProgress > 1 {
				displayProgress = 1
			}

			self.progressView.progress = displayProgress

			if self.autoCollapse {
				self.triggerDelayedAutoCollapse()
			}
		}

		get {
			return _progress
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupSubviews()

		progressView.progress = 0.75
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func setupSubviews() {
		self.clipsToBounds = true

		contentView.translatesAutoresizingMaskIntoConstraints = false
		progressView.translatesAutoresizingMaskIntoConstraints = false
		progressLabelView.translatesAutoresizingMaskIntoConstraints = false

		contentView.setContentHuggingPriority(.required, for: .vertical)
		progressView.setContentHuggingPriority(.required, for: .vertical)
		progressLabelView.setContentHuggingPriority(.required, for: .vertical)
		progressLabelView.setContentCompressionResistancePriority(.required, for: .vertical)

		contentView.addSubview(progressView)
		contentView.addSubview(progressLabelView)

		progressView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
		progressView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
		progressView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true

		progressLabelView.text = " "
		progressLabelView.textAlignment = .center
		progressLabelView.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
		progressLabelView.lineBreakMode = .byTruncatingTail

		progressLabelView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
		progressLabelView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
		progressLabelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
		progressLabelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

		self.addSubview(contentView)

		contentViewHeight = contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height

		contentView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
		contentView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
		contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true

		heightConstraint = self.heightAnchor.constraint(equalToConstant: 0)
		heightConstraint?.isActive = true

		Theme.shared.register(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		contentView.backgroundColor = collection.toolbarColors.backgroundColor
		progressLabelView.textColor = collection.toolbarColors.labelColor

		progressView.trackTintColor = collection.toolbarColors.backgroundColor?.lighter(0.1)
		progressView.tintColor = collection.toolbarColors.tintColor
	}

	func collapse(_ collapse: Bool, animate: Bool) {
		DispatchQueue.main.async {
			if self.isCollapsed != collapse {
				self.isCollapsed = collapse

				if animate {
					self.superview?.layoutIfNeeded()
				}

				if collapse {
					self.heightConstraint?.constant = 0
				} else {
					self.heightConstraint?.constant = self.contentViewHeight
				}

				if animate {
					UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
						self.superview?.layoutIfNeeded()
					})
				}
			}
		}
	}

	func update(with message: String?, progress: Float) {
		DispatchQueue.main.async {
			self.progressLabelView.text = message ?? ""
			self.progress = progress
		}
	}

	private var lastShouldCollapseTime : TimeInterval = 0
	private func triggerDelayedAutoCollapse() {
		let shouldCollapse = (self.progress == 1)
		var delay : TimeInterval = 0.1

		if shouldCollapse {
			lastShouldCollapseTime = Date.timeIntervalSinceReferenceDate
			delay = 0.5
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
			self.evaluateAutoCollapse(shouldCollapse)
		}
	}

	private func evaluateAutoCollapse(_ shouldCollapse: Bool) {
		let shouldCurrentlyCollapse = (self.progress == 1)
		let doAutoCollapse = (shouldCollapse == shouldCurrentlyCollapse) && shouldCollapse && ((Date.timeIntervalSinceReferenceDate - lastShouldCollapseTime) > 0.4)

		self.collapse(doAutoCollapse, animate: true)
	}
}
