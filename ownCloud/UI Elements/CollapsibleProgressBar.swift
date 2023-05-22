//
//  CollapsibleProgressBar.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudAppShared

private struct CollapsibleProgressBarUpdate {
	var progress: Float?
	var message: String?
}

class CollapsibleProgressBar: UIView, Themeable {
	var contentView : UIView = UIView()
	var fillView : UIView = UIView()
	var progressView : UIProgressView = UIProgressView()
	var progressLabelView : UILabel = UILabel(frame: CGRect.zero)
	var contentViewHeight : CGFloat = 0
	var heightConstraint : NSLayoutConstraint?
	var fillViewExpandedTopConstraint : NSLayoutConstraint?
	var fillViewCollapsedTopConstraint : NSLayoutConstraint?
	var isCollapsed : Bool = true
	internal var _autoCollapse : Bool = true
	var autoCollapse : Bool {
		set(newAutoCollapse) {
			if _autoCollapse != newAutoCollapse {
				let oldAutoCollapse = _autoCollapse

				_autoCollapse = newAutoCollapse

				if oldAutoCollapse {
					self.collapse(false, animate: true)
				} else {
					self.triggerDelayedAutoCollapse()
				}
			}
		}

		get {
			return _autoCollapse
		}
	}

	// MARK: - Progress property
	internal var _progress : Float = 0
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

	// MARK: - Init
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

	// MARK: - Subviews
	func setupSubviews() {
		self.clipsToBounds = true

		fillView.translatesAutoresizingMaskIntoConstraints = false
		contentView.translatesAutoresizingMaskIntoConstraints = false
		progressView.translatesAutoresizingMaskIntoConstraints = false
		progressLabelView.translatesAutoresizingMaskIntoConstraints = false

		contentView.setContentHuggingPriority(.required, for: .vertical)
		progressView.setContentHuggingPriority(.required, for: .vertical)
		progressLabelView.setContentHuggingPriority(.required, for: .vertical)
		progressLabelView.setContentCompressionResistancePriority(.required, for: .vertical)

		contentView.addSubview(progressView)
		contentView.addSubview(progressLabelView)

		NSLayoutConstraint.activate([
			progressView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
			progressView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
			progressView.topAnchor.constraint(equalTo: contentView.topAnchor)
		])

		progressLabelView.text = " "
		progressLabelView.textAlignment = .center
		progressLabelView.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
		progressLabelView.lineBreakMode = .byTruncatingTail

		NSLayoutConstraint.activate([
			progressLabelView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
			progressLabelView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
			progressLabelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
			progressLabelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
		])

		self.addSubview(contentView)
		self.addSubview(fillView)

		contentViewHeight = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

		fillViewExpandedTopConstraint = fillView.topAnchor.constraint(equalTo:self.safeAreaLayoutGuide.bottomAnchor).with(priority: .defaultHigh)
		fillViewCollapsedTopConstraint = fillView.topAnchor.constraint(equalTo: self.bottomAnchor).with(priority: .defaultHigh)

		heightConstraint = fillView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)

		NSLayoutConstraint.activate([
			fillView.leftAnchor.constraint(equalTo: self.leftAnchor),
			fillView.rightAnchor.constraint(equalTo: self.rightAnchor),
			fillView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			fillViewCollapsedTopConstraint!,

			contentView.leftAnchor.constraint(equalTo: self.leftAnchor),
			contentView.rightAnchor.constraint(equalTo: self.rightAnchor),
			contentView.topAnchor.constraint(equalTo: self.topAnchor),

			heightConstraint!
		])

		Theme.shared.register(client: self)
	}

	// MARK: - Theming
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		fillView.backgroundColor = collection.toolbarColors.backgroundColor
		contentView.backgroundColor = collection.toolbarColors.backgroundColor
		progressLabelView.textColor = collection.toolbarColors.labelColor

		progressView.trackTintColor = collection.toolbarColors.backgroundColor?.lighter(0.1)
		progressView.tintColor = collection.toolbarColors.tintColor
	}

	// MARK: - Collapsing
	func collapse(_ collapse: Bool, animate: Bool) {
		OnMainThread {
			if self.isCollapsed != collapse {
				self.isCollapsed = collapse

				if animate {
					self.superview?.layoutIfNeeded()
				}

				if collapse {
					self.heightConstraint?.constant = 0
					self.fillViewExpandedTopConstraint?.isActive = false
					self.fillViewCollapsedTopConstraint?.isActive = true
				} else {
					self.heightConstraint?.constant = self.contentViewHeight
					self.fillViewCollapsedTopConstraint?.isActive = false
					self.fillViewExpandedTopConstraint?.isActive = true
				}

				if animate {
					UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
						self.superview?.layoutIfNeeded()
					})
				}
			}
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

		OnMainThread(after: delay) {
			self.evaluateAutoCollapse(shouldCollapse)
		}
	}

	private func evaluateAutoCollapse(_ shouldCollapse: Bool) {
		let shouldCurrentlyCollapse = (self.progress == 1)
		let doAutoCollapse = (shouldCollapse == shouldCurrentlyCollapse) && shouldCollapse && ((Date.timeIntervalSinceReferenceDate - lastShouldCollapseTime) > 0.4)

		self.collapse(doAutoCollapse, animate: true)
	}

	// MARK: - Update coalescating
	private var scheduledUpdate : CollapsibleProgressBarUpdate?

	private func performUpdate() {
		OCSynchronized(self) {
			if scheduledUpdate != nil {
				if let message : String = scheduledUpdate?.message {
					self.progressLabelView.text = message
				}

				if let progress : Float = scheduledUpdate?.progress {
					self.progress = progress
				}

				scheduledUpdate = nil // This update has been handled => next update will need to be scheduled again
			}
		}
	}

	func update(with message: String?, progress: Float?) {
		var doDispatch : Bool = false

		OCSynchronized(self) {
			if scheduledUpdate == nil {
				doDispatch = true // Only schedule a new update if one isn't underway already

				scheduledUpdate = CollapsibleProgressBarUpdate() // => A new update is now underway
			}

			if message != nil {
				scheduledUpdate?.message = message
			}

			if progress != nil {
				scheduledUpdate?.progress = progress
			}

			if doDispatch {
				OnMainThread {
					self.performUpdate()
				}
			}
		}
	}
}
