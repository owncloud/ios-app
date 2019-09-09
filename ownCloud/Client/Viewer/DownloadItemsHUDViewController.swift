//
//  DownloadItemsHUDViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.06.19.
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
import ownCloudSDK

typealias DownloadItemsHUDViewControllerCompletionHandler = (Error?, [OCFile]?) -> Void

class DownloadItemsHUDViewController: CardViewController {
	var items : [OCItem]
	var downloadedFiles : [OCFile] = [OCFile]()
	var downloadError : Error?
	var downloadProgress : [Progress] = [Progress]()
	var completion : DownloadItemsHUDViewControllerCompletionHandler?

	var messageLabel : UILabel
	var cancelButton : UIButton
	var progressView : UIProgressView
	var progressSummarizer : ProgressSummarizer
	weak var core : OCCore?

	init(core: OCCore, downloadItems: [OCItem], completion: @escaping DownloadItemsHUDViewControllerCompletionHandler) {
		self.core = core
		self.items = downloadItems
		self.completion = completion

		messageLabel = UILabel()
		progressView = UIProgressView(progressViewStyle: .bar)
		cancelButton = ThemeButton()
		progressSummarizer = ProgressSummarizer()

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		progressSummarizer.removeObserver(self)
	}

	override func loadView() {
		let containerInsets = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
		let messageProgressSpacing : CGFloat = 15
		let progressCancelSpacing : CGFloat = 25
		let containerView = UIView()

		super.loadView()

		cancelButton.setTitle("Cancel".localized, for: .normal)
		cancelButton.addTarget(self, action: #selector(self.cancel), for: .touchUpInside)

		messageLabel.text = "Preparing…".localized // Needed so the messageLabel doesn't have a zero height after initial layout
		messageLabel.sizeToFit()

		messageLabel.setContentHuggingPriority(.required, for: .vertical)
		progressView.setContentHuggingPriority(.required, for: .vertical)
		cancelButton.setContentHuggingPriority(.required, for: .vertical)

		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		progressView.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		containerView.translatesAutoresizingMaskIntoConstraints = false

		containerView.addSubview(messageLabel)
		containerView.addSubview(progressView)
		containerView.addSubview(cancelButton)

		view.addSubview(containerView)

		NSLayoutConstraint.activate([
			messageLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
			messageLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),

			progressView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
			progressView.rightAnchor.constraint(equalTo: containerView.rightAnchor),

			cancelButton.leftAnchor.constraint(equalTo: containerView.leftAnchor),
			cancelButton.rightAnchor.constraint(equalTo: containerView.rightAnchor),

			messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
			progressView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: messageProgressSpacing),
			cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: progressCancelSpacing),
			cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

			containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: containerInsets.top),
			containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -containerInsets.bottom),
			containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: containerInsets.left),
			containerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -containerInsets.right)
		])
	}

	@objc func cancel() {
		self.dismiss(animated: true, completion: {
			self.completed(with: NSError(ocError: .cancelled))

			for progress in self.downloadProgress {
				progress.cancel()
			}
		})
	}

	func presentHUDOn(viewController: UIViewController) {
		if let core = core {
			// Remove already downloaded files
			items = items.filter({ (item) -> Bool in
				if core.localCopy(of: item) != nil {
					if let file = item.file(with: core) {
						downloadedFiles.append(file)

						return false
					}
				}

				return true
			})

			// Check if any items remain
			if items.count > 0 {
				progressSummarizer.addObserver(self, notificationBlock: { [weak self] (_, summary) in
					if let progressView = self?.progressView {
						self?.messageLabel.text = summary.message ?? "Preparing…".localized
						summary.update(progressView: progressView)
					}
				})

				let downloadGroup = DispatchGroup()

				for item in items {
					downloadGroup.enter()

					if let progress = core.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { (error, _, _, file) in
						if error != nil {
							Log.error("DownloadItemsHUDViewController: error \(String(describing: error)) downloading \(String(describing: item.path))")
							self.downloadError = error
						} else {
							self.downloadedFiles.append(file!)
						}
						downloadGroup.leave()
					}) {
						downloadProgress.append(progress)
						progressSummarizer.startTracking(progress: progress)
					}
				}

				progressSummarizer.update()

				// Present
				viewController.present(asCard: self, animated: true, withHandle: false, dismissable: false, completion: {
					downloadGroup.notify(queue: .main) { [weak self] in
						OnMainThread {
							if let self = self {
								self.dismiss(animated: true, completion: {
									if let error = self.downloadError {
										self.completed(with: error)
									} else {
										self.completed(files: self.downloadedFiles)
									}
								})
							}
						}
					}
				})
			} else {
				// Done
				completed(files: downloadedFiles)
			}
		} else {
			// No core
			completed(with: NSError(ocError: .internal))
		}
	}

	func completed(with error: Error? = nil, files: [OCFile]? = nil) {
		if let completion = completion {
			completion(error, files)
			self.completion = nil
		}
	}

	// MARK: - Themeable
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		progressView.applyThemeCollection(collection)
		messageLabel.applyThemeCollection(collection)
		cancelButton.applyThemeCollection(collection)

		super.applyThemeCollection(theme: theme, collection: collection, event: event)
	}
}
