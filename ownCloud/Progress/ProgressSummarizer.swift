//
//  ProgressSummarizer.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

struct ProgressSummary {
	var indeterminate : Bool
	var progress : Double
	var message : String?
	var progressCount : Int
}

typealias ProgressSummarizerNotificationBlock =  (_ summarizer : ProgressSummarizer, _ summary : ProgressSummary) -> Void

private struct ProgressSummaryNotificationObserver {
	weak var observer : AnyObject?
	var notificationBlock : ProgressSummarizerNotificationBlock
}

class ProgressSummarizer: NSObject {
	// MARK: - Init & Deinit
	private var observerContextTarget : Int = 0
	private var observerContext : UnsafeMutableRawPointer?

	var trackedProgress : [Progress] = []

	override init() {
		observerContext = UnsafeMutableRawPointer(&observerContextTarget)

		super.init()
	}

	deinit {
		OCSynchronized(self) {
			for progress in trackedProgress {
				self.stopTracking(progress: progress, remove: false)
			}
		}
	}

	// MARK: - Shared summarizers
	private static var sharedSummarizers : [NSObject : ProgressSummarizer] = [:]
	static func shared(for identifier: NSObject) -> ProgressSummarizer {
		var sharedSummarizer : ProgressSummarizer?

		OCSynchronized(ProgressSummarizer.self) {
			sharedSummarizer = sharedSummarizers[identifier]

			if sharedSummarizer == nil {
				sharedSummarizer = ProgressSummarizer()
				sharedSummarizers[identifier] = sharedSummarizer
			}
		}

		return sharedSummarizer!
	}

	static func shared(forCore core: OCCore) -> ProgressSummarizer {
		return self.shared(for: core.bookmark.uuid as NSObject)
	}

	// MARK: - Start/Stop tracking of progress objects
	func startTracking(progress: Progress) {
		OCSynchronized(self) {
			if !trackedProgress.contains(progress) {
				trackedProgress.append(progress)

				progress.addObserver(self, forKeyPath: "fractionCompleted", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
				progress.addObserver(self, forKeyPath: "isFinished", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
				progress.addObserver(self, forKeyPath: "isIndeterminate", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
				progress.addObserver(self, forKeyPath: "localizedDescription", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
			}
		}
	}

	func stopTracking(progress: Progress, remove: Bool = true) {
		OCSynchronized(self) {
			if !trackedProgress.contains(progress) {
				progress.removeObserver(self, forKeyPath: "fractionCompleted", context: observerContext)
				progress.removeObserver(self, forKeyPath: "isFinished", context: observerContext)
				progress.removeObserver(self, forKeyPath: "isIndeterminate", context: observerContext)
				progress.removeObserver(self, forKeyPath: "localizedDescription", context: observerContext)

				if remove {
					trackedProgress.remove(at: trackedProgress.index(of: progress)!)
				}
			}
		}
	}

	// MARK: - Change tracking (internal)
	// Using the Objective-C API for KVO here has the benefit of not having to track NSKeyValueObservation objects for the Progress objects.
	// Simplifies internal book-keeping, should provide better performance and a lower memory footprint - all while providing everything we need.
	// swiftlint:disable block_based_kvo
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == observerContext {
			if let progress = object as? Progress {
				if progress.isFinished {
					self.stopTracking(progress: progress)
				}

				self.setNeedsUpdate()
			}
		}
	}
	// swiftlint:enable block_based_kvo

	// MARK: - Update throttling
	/// Minimum amount of time between two updates (throttling)
	public var minimumUpdateTimeInterval : TimeInterval = 0.1

	private var updateInProgress : Bool = false

	private func setNeedsUpdate() {
		var scheduleUpdate = false

		OCSynchronized(self) {
			if !updateInProgress {
				updateInProgress = true
				scheduleUpdate = true
			}
		}

		if scheduleUpdate {
			if minimumUpdateTimeInterval > 0 {
				DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + minimumUpdateTimeInterval) {
					self.performNeededUpdate()
				}
			} else {
				DispatchQueue.main.async {
					self.performNeededUpdate()
				}
			}
		}
	}

	private func performNeededUpdate() {
		OCSynchronized(self) {
			self.update()

			updateInProgress = false
		}
	}

	func update() {
		let summary : ProgressSummary = summarize()

		OCSynchronized(self) {
			for observer in observers {
				if observer.observer != nil {
					observer.notificationBlock(self, summary)
				}
			}
		}
	}

	// MARK: - Change notifications
	private var observers : [ProgressSummaryNotificationObserver] = []
	func addObserver(_ observer: AnyObject, notificationBlock: @escaping ProgressSummarizerNotificationBlock) {
		OCSynchronized(self) {
			observers.append(ProgressSummaryNotificationObserver(observer: observer, notificationBlock: notificationBlock))
		}
	}

	func removeObserver(_ observer: AnyObject) {
		OCSynchronized(self) {
			if let removeIndex : Int = observers.index(where: { (observerRecord) -> Bool in
				return observerRecord.observer === observer
			}) {
				observers.remove(at: removeIndex)
			}
		}
	}

	// MARK: - Summary computation
	func summarize() -> ProgressSummary {
		var summary : ProgressSummary = ProgressSummary(indeterminate: false, progress: 0, message: nil, progressCount: 0)
		var totalUnitCount : Int64 = 0
		var completedUnitCount : Int64 = 0

		OCSynchronized(self) {
			for progress in trackedProgress {
				if progress.isIndeterminate {
					summary.indeterminate = true
				}

				if let message = progress.localizedDescription {
					// Pick the first localized description that we encounter as message, because it's also the oldest, longest-running one.
					if summary.message == nil {
						summary.message = message
					}
				}

				totalUnitCount += progress.totalUnitCount
				completedUnitCount += progress.completedUnitCount
			}

			summary.progressCount = trackedProgress.count

			if totalUnitCount == 0 {
				if trackedProgress.count == 0 {
					summary.progress = 1
				} else {
					summary.indeterminate = true
				}
			} else {
				summary.progress = Double(completedUnitCount) / Double(totalUnitCount)
			}
		}

		return summary
	}
}
