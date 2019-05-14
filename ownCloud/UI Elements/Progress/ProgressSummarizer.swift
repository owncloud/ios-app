//
//  ProgressSummarizer.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.04.18.
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
import ownCloudSDK

struct ProgressSummary : Equatable {
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
	var trackedProgressByType : [ OCEventType : [Progress] ] = [ : ]
	var trackedProgressByTypeCount : [ OCEventType : Int ] = [ : ]

	override init() {
		observerContext = UnsafeMutableRawPointer(&observerContextTarget)

		super.init()
	}

	deinit {
		OCSynchronized(self) {
			let existingTrackedProgress = trackedProgress

			for progress in existingTrackedProgress {
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

	static func shared(forBookmark bookmark: OCBookmark) -> ProgressSummarizer {
		return self.shared(for: bookmark.uuid as NSObject)
	}

	static func shared(forCore core: OCCore) -> ProgressSummarizer {
		return self.shared(forBookmark: core.bookmark)
	}

	// MARK: - Start/Stop tracking of progress objects
	func startTracking(progress: Progress) {
		OCSynchronized(self) {
			if !trackedProgress.contains(progress) {
				trackedProgress.insert(progress, at: 0)

				if progress.eventType != .none {
					if trackedProgressByType[progress.eventType] != nil {
						trackedProgressByType[progress.eventType]?.append(progress)
					} else {
						trackedProgressByType[progress.eventType] = [ progress ]
					}

					// Count the number of progress objects with the same type
					trackedProgressByTypeCount[progress.eventType] = (trackedProgressByTypeCount[progress.eventType] ?? 0) + 1
				}

				progress.addObserver(self, forKeyPath: "fractionCompleted", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
				progress.addObserver(self, forKeyPath: "isFinished", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
				progress.addObserver(self, forKeyPath: "isIndeterminate", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)
				progress.addObserver(self, forKeyPath: "localizedDescription", options: NSKeyValueObservingOptions(rawValue: 0), context: observerContext)

				self.setNeedsUpdate()
			}
		}
	}

	func stopTracking(progress: Progress, remove: Bool = true) {
		OCSynchronized(self) {
			if let trackedProgressIndex = trackedProgress.index(of: progress) {
				progress.removeObserver(self, forKeyPath: "fractionCompleted", context: observerContext)
				progress.removeObserver(self, forKeyPath: "isFinished", context: observerContext)
				progress.removeObserver(self, forKeyPath: "isIndeterminate", context: observerContext)
				progress.removeObserver(self, forKeyPath: "localizedDescription", context: observerContext)

				if remove {
					trackedProgress.remove(at: trackedProgressIndex)

					if progress.eventType != .none {
						if let progressByTypeIndex = trackedProgressByType[progress.eventType]?.index(of: progress) {
							trackedProgressByType[progress.eventType]?.remove(at: progressByTypeIndex)

							let remainingProgressByType = (trackedProgressByType[progress.eventType]?.count ?? 0)

							if remainingProgressByType < 2 {
								// Reset the number of progress objects with the same type only after at least (all-1) have finished
								// to make sure using trackedProgressByTypeCount leads to an evenly drawn progress bar, but also
								// resets the count if only one is left, so the next that's scheduled doesn't bring the message back to "x of previousAll"
								trackedProgressByTypeCount[progress.eventType] = remainingProgressByType
							}
						}
					}

					self.setNeedsUpdate()
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
			self.setNeedsUpdate()
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
				OnMainThread(after: minimumUpdateTimeInterval) {
					self.performNeededUpdate()
				}
			} else {
				OnMainThread {
					self.performNeededUpdate()
				}
			}
		}
	}

	private func performNeededUpdate() {
		OCSynchronized(self) {
			self.update()

			self.updateInProgress = false
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

	// MARK: - Fallback summaries (to be used by the observers at their own descretion)
	internal var _fallbackSummary : ProgressSummary?
	public var fallbackSummary : ProgressSummary? {
		set(newFallbackSummary) {
			if _fallbackSummary != newFallbackSummary {
				_fallbackSummary = newFallbackSummary
				self.setNeedsUpdate()
			}
		}

		get {
			return _fallbackSummary
		}
	}

	private var fallbackSummaries : [ProgressSummary] = []

	func pushFallbackSummary(summary : ProgressSummary) {
		OCSynchronized(self) {
			fallbackSummaries.append(summary)

			if fallbackSummaries.count == 1 {
				self.fallbackSummary = summary
			}
		}
	}

	func popFallbackSummary(summary : ProgressSummary) {
		OCSynchronized(self) {
			if let index = fallbackSummaries.index(of: summary) {
				fallbackSummaries.remove(at: index)

				if index == 0 {
					if fallbackSummaries.count > 0 {
						self.fallbackSummary = fallbackSummaries.first

					} else {
						self.fallbackSummary = nil
					}
				}
			}
		}
	}

	// MARK: - Priority summaries (to be used in favor of everything else whenever they exist)
	internal var _prioritySummary : ProgressSummary?
	public var prioritySummary : ProgressSummary? {
		set(newPrioritySummary) {
			if _prioritySummary != newPrioritySummary {
				_prioritySummary = newPrioritySummary
				self.setNeedsUpdate()
			}
		}

		get {
			return _prioritySummary
		}
	}

	private var prioritySummaries : [ProgressSummary] = []

	func pushPrioritySummary(summary : ProgressSummary) {
		OCSynchronized(self) {
			prioritySummaries.append(summary)

			self.prioritySummary = summary
		}
	}

	func popPrioritySummary(summary : ProgressSummary) {
		OCSynchronized(self) {
			if let index = prioritySummaries.index(of: summary) {
				prioritySummaries.remove(at: index)

				if prioritySummaries.count == 0 {
					self.prioritySummary = nil
				} else if prioritySummaries.count == index {
					self.prioritySummary = prioritySummaries.last
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
		var completedFraction : Double = 0
		var totalFraction : Double = 0
		var completedProgress : [Progress]?
		var isGroupedProgress : Bool = false

		OCSynchronized(self) {
			var usedProgress : Int = 0

			for progress in trackedProgress {
				// Only consider progress objects that have a description (those without have to be considered to be not active and/or unsuitable)
				if let message = progress.localizedDescription {
					if message.count > 0 {
						if progress.isIndeterminate {
							summary.indeterminate = true
						}

						if progress.isFinished {
							if completedProgress == nil {
								completedProgress = []
							}
							completedProgress?.append(progress)
						}

						// Pick the first localized description that we encounter as message, because it's also the most recent one (=> trackedProgress is reversed above!)
						if summary.message == nil {
							summary.message = message

							if progress.eventType != .none, let progressOfSameType = trackedProgressByType[progress.eventType], progressOfSameType.count > 1 {
								var multiMessage : String?
								var sameTypeCount = progressOfSameType.count
								let totalSameTypeCount = trackedProgressByTypeCount[progress.eventType] ?? sameTypeCount

								for progress in progressOfSameType {
									if !progress.isIndeterminate, progress.isFinished {
										sameTypeCount -= 1
									}
								}

								if sameTypeCount > 1 {
									switch progress.eventType {
										case .createFolder:
											multiMessage = NSString(format:"Creating %ld of %ld folders…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .move:
											multiMessage = NSString(format:"Moving %ld of %ld items…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .copy:
											multiMessage = NSString(format:"Copying %ld of %ld items…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .delete:
											multiMessage = NSString(format:"Deleting %ld of %ld items…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .upload:
											multiMessage = NSString(format:"Uploading %ld of %ld files…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .download:
											multiMessage = NSString(format:"Downloading %ld of %ld files…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .update:
											multiMessage = NSString(format:"Updating %ld of %ld items…".localized as NSString, sameTypeCount, totalSameTypeCount) as String

										case .createShare, .updateShare, .deleteShare, .decideOnShare: break
										case .none, .retrieveThumbnail, .retrieveItemList, .retrieveShares, .issueResponse: break
									}

									if multiMessage != nil {
										var multiProgress : Double = Double(totalSameTypeCount - sameTypeCount) / Double(totalSameTypeCount) // add progress for already completed & removed progress

										isGroupedProgress = true

										summary.message = multiMessage

										for progress in progressOfSameType {
											if !progress.isIndeterminate, !progress.isFinished {
												multiProgress += (progress.fractionCompleted / Double(totalSameTypeCount))
											}
										}

										summary.progress = multiProgress

										usedProgress += sameTypeCount
										break
									}
								}
							}
						}

						if !progress.isIndeterminate {
							totalUnitCount += progress.totalUnitCount
							completedUnitCount += progress.completedUnitCount

							if progress.totalUnitCount > 0 {
								totalFraction += 1
								completedFraction += progress.fractionCompleted
							}
						}

						usedProgress += 1
					}
				}
			}

			summary.progressCount = usedProgress

			if !isGroupedProgress {
				if totalUnitCount == 0 {
					if usedProgress == 0 {
						summary.progress = 1
					} else {
						summary.indeterminate = true
					}
				} else {
					if totalFraction != 0 {
						summary.progress = completedFraction / totalFraction
					} else {
						summary.progress = Double(completedUnitCount) / Double(totalUnitCount)
					}
				}
			}

			if let completedProgress = completedProgress {
				for removeProgress in completedProgress {
					self.stopTracking(progress: removeProgress)
				}
			}
		}

		return summary
	}
}
