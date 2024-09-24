//
//  BookmarkSetupStepPrepopulateViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.09.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudAppShared
import ownCloudSDK

class BookmarkSetupStepProgressViewController: BookmarkSetupStepViewController {
	open var cancelled : Bool = false

	open var progressView : ProgressView

	var progressMessageObservation : NSKeyValueObservation?
	var progressValueObservation : NSKeyValueObservation?
	open var progress : Progress? {
		willSet {
			progressMessageObservation?.invalidate()
			progressMessageObservation = nil

			progressView.progress = nil
		}

		didSet {
			if progress != nil {
				progressMessageObservation = progress?.observe(\Progress.localizedDescription, options: NSKeyValueObservingOptions.initial, changeHandler: { [weak self] progress, _ in
					OnMainThread {
						self?.messageLabel?.text = progress.localizedDescription
					}
				})

				progressView.progress = progress
			}
		}
	}

	public override init(with setupViewController: BookmarkSetupViewController, step: BookmarkComposer.Step) {
		progressView = ProgressView()
		progressView.translatesAutoresizingMaskIntoConstraints = false

		let indeterminateProgress = Progress.indeterminate()
		indeterminateProgress.isCancellable = false
		progressView.progress = indeterminateProgress

		super.init(with: setupViewController, step: step)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override open func viewDidLoad() {
		super.viewDidLoad()
		self.contentView = progressView
	}

	override func handleContinue() {
		if !self.cancelled {
			self.handleCancellation()
		}

		self.cancelled = true
	}

	func handleCancellation() {
		// Subclassing point
	}
}

class BookmarkSetupStepPrepopulateViewController: BookmarkSetupStepProgressViewController {
	public override init(with setupViewController: BookmarkSetupViewController, step: BookmarkComposer.Step) {
		super.init(with: setupViewController, step: step)

		self.stepTitle = OCLocalizedString("Preparing account", nil)
		self.stepMessage = OCLocalizedString("Please wait…", nil)

		self.continueButtonLabelText = OCLocalizedString("Skip", nil)

		self.progress = setupViewController.composer?.prepopulate(completion: self.composerCompletion)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func handleCancellation() {
		self.progress?.cancel()
	}
}
