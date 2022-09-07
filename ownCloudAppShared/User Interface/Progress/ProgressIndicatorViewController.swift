//
//  ProgressIndicatorViewController.swift
//  ownCloud Share Extension
//
//  Created by Felix Schwarz on 07.08.20.
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

open class ProgressIndicatorViewController: UIViewController, Themeable {
	open var cancelled : Bool = false
	open var cancelHandler : (() -> Void)?

	open var progressView : UIProgressView
	open var activityIndicator : UIActivityIndicatorView
	open var label : UILabel
	open var titleLabel : UILabel?
	open var cancelButton : UIButton?

	var progressMessageObservation : NSKeyValueObservation?
	var progressValueObservation : NSKeyValueObservation?
	open var progress : Progress? {
		willSet {
			progressMessageObservation?.invalidate()
			progressMessageObservation = nil

			progressValueObservation?.invalidate()
			progressValueObservation = nil
		}

		didSet {
			if progress != nil {
				progressMessageObservation = progress?.observe(\Progress.localizedDescription, options: NSKeyValueObservingOptions.initial, changeHandler: { [weak self] progress, _ in
					OnMainThread {
						self?.label.text = progress.localizedDescription
					}
				})

				progressValueObservation = progress?.observe(\Progress.fractionCompleted, options: NSKeyValueObservingOptions.initial, changeHandler: { [weak self] progress, _ in
					OnMainThread {
						if progress.isIndeterminate {
							self?.activityIndicator.isHidden = false
							self?.progressView.isHidden = true
							self?.activityIndicator.startAnimating()
						} else {
							self?.activityIndicator.stopAnimating()
							self?.activityIndicator.isHidden = true
							self?.progressView.isHidden = false
						}
					}
				})
			}
		}
	}

	public init(initialTitleLabel: String? = nil, initialProgressLabel: String?, progress : Progress?, cancelLabel: String? = nil, cancelHandler: (() -> Void)? = nil) {
		progressView = UIProgressView(progressViewStyle: .bar)
		progressView.translatesAutoresizingMaskIntoConstraints = false

		if #available(iOS 13, *) {
			activityIndicator = UIActivityIndicatorView(style: .large)
		} else {
			activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
		}
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.isHidden = true

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false

		super.init(nibName: nil, bundle: nil)

		self.progress = progress

		if let initialTitleLabel = initialTitleLabel {
			titleLabel = UILabel()
			titleLabel?.translatesAutoresizingMaskIntoConstraints = false
			titleLabel?.text = initialTitleLabel
			titleLabel?.font = .preferredFont(forTextStyle: .title2)

			label.font = .preferredFont(forTextStyle: .subheadline)
		}

		if let initialProgressLabel = initialProgressLabel {
			label.text = initialProgressLabel
		}

		self.cancelHandler = cancelHandler

		if cancelHandler != nil {
			cancelButton = ThemeButton(type: .system)
			cancelButton?.translatesAutoresizingMaskIntoConstraints = false

			cancelButton?.setTitle(cancelLabel ?? "Cancel".localized, for: .normal)

			cancelButton?.addTarget(self, action: #selector(self.cancel), for: .primaryActionTriggered)
		}
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override open func loadView() {
		let rootView = UIView()
		let centerView = UIView()

		rootView.translatesAutoresizingMaskIntoConstraints = false
		centerView.translatesAutoresizingMaskIntoConstraints = false

		centerView.addSubview(progressView)
		centerView.addSubview(label)

		if let titleLabel = titleLabel {
			centerView.addSubview(titleLabel)
		}

		if let cancelButton = cancelButton {
			centerView.addSubview(cancelButton)
		}

		rootView.addSubview(centerView)
		rootView.addSubview(activityIndicator)

		let outerSpacing : CGFloat = 10
		let titleLabelSpacing : CGFloat = 5
		let labelProgressBarSpacing : CGFloat  = 20
		let cancelProgressBarSpacing : CGFloat  = 40
		let progressBarWidth : CGFloat  = 280

		var constraints = [
			progressView.leftAnchor.constraint(equalTo: centerView.leftAnchor),
			progressView.rightAnchor.constraint(equalTo: centerView.rightAnchor),

			label.leftAnchor.constraint(greaterThanOrEqualTo: centerView.leftAnchor),
			label.rightAnchor.constraint(lessThanOrEqualTo: centerView.rightAnchor),

			label.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),

			progressView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: labelProgressBarSpacing),

			centerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: outerSpacing),
			centerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -outerSpacing),

			centerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
			centerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),

			centerView.widthAnchor.constraint(equalToConstant: progressBarWidth),

			activityIndicator.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),
			activityIndicator.bottomAnchor.constraint(equalTo: centerView.topAnchor, constant:-labelProgressBarSpacing),
			activityIndicator.widthAnchor.constraint(equalToConstant: 20),
			activityIndicator.heightAnchor.constraint(equalToConstant: 20)
		]

		if let titleLabel = titleLabel {
			constraints.append(contentsOf: [
				titleLabel.topAnchor.constraint(equalTo: centerView.topAnchor, constant: outerSpacing),
				titleLabel.centerXAnchor.constraint(greaterThanOrEqualTo: centerView.centerXAnchor),
				titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: centerView.leftAnchor),
				titleLabel.rightAnchor.constraint(lessThanOrEqualTo: centerView.rightAnchor),
				label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleLabelSpacing)
			])
		} else {
			constraints.append(contentsOf: [
				label.topAnchor.constraint(equalTo: centerView.topAnchor, constant: outerSpacing),
			])
		}

		if let cancelButton = cancelButton {
			constraints.append(contentsOf: [
				cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: cancelProgressBarSpacing),
				cancelButton.bottomAnchor.constraint(equalTo: centerView.bottomAnchor, constant: -outerSpacing),

				cancelButton.centerXAnchor.constraint(equalTo: centerView.centerXAnchor)
			])
		} else {
			constraints.append(label.bottomAnchor.constraint(equalTo: centerView.bottomAnchor, constant: -outerSpacing))
		}

		NSLayoutConstraint.activate(constraints)

		self.view = rootView
	}

	override open func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	@objc open func cancel() {
		self.cancelled = true

		cancelHandler?()
		cancelHandler = nil
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.tableBackgroundColor

		self.progressView.applyThemeCollection(collection)
		self.titleLabel?.applyThemeCollection(collection, itemStyle: .title, itemState: .normal)
		self.label.applyThemeCollection(collection)
		self.cancelButton?.applyThemeCollection(collection)
		self.activityIndicator.style = collection.activityIndicatorViewStyle
	}

	open func update(progress: Float? = nil, text: String? = nil) {
		OnMainThread {
			if let progress = progress {
				self.progressView.progress = progress
			}
			if let text = text {
				self.label.text = text
			}
		}
	}
}
