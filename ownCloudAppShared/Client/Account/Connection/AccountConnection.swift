//
//  AccountConnection.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 16.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp
import ownCloudSDK

open class AccountConnection: NSObject {
	public enum Status: String {
		case noCore
		case offline
		case connecting
		case coreAvailable
		case online

		case busy
		case authenticationError
	}

	public static let StatusChangedNotification = NSNotification.Name("AccountConnectionStatusChanged")

	open var bookmark: OCBookmark
	open weak var core: OCCore?

	var consumers: [AccountConnectionConsumer] = []

	public dynamic var status: Status = .noCore {
		didSet {
			Log.debug("Account connection status: \(status.rawValue)")

			let newStatus = status

			if let richStatus = richStatus {
				richStatus.status = newStatus
				self.richStatus = richStatus
			} else {
				self.richStatus = AccountConnectionRichStatus(kind: .status, status: newStatus)
			}

			OnMainThread {
				self.enumerateConsumers { consumer in
					consumer.statusObserver?.account(connection: self, changedStatusTo: newStatus, initial: false)
				}

				NotificationCenter.default.post(name: AccountConnection.StatusChangedNotification, object: self)
			}
		}
	}
	@objc public dynamic var richStatus: AccountConnectionRichStatus?

	var skipAuthorizationFailure : Bool = false

	public typealias CompletionHandler = (_ error: Error?) -> Void

	public init(bookmark: OCBookmark) {
		self.bookmark = bookmark
		self.taskQueue = OCAsyncSequentialQueue(queue: AccountConnectionPool.shared.serialQueue)
		self.progressSummarizer = ProgressSummarizer.shared(forBookmark: bookmark)

		super.init()

		setupProgressSummarizer()
	}

	deinit {
		shutdownProgressSummarizer()
	}

	// MARK: - Queue
	private var taskQueue: OCAsyncSequentialQueue

	func queue(completion: CompletionHandler? = nil, _ block: @escaping (_ connection: AccountConnection, _ jobDone: @escaping () -> Void) -> Void) {
		AccountConnectionPool.shared.taskQueue.async({ [weak self] (jobDone) in
			guard let self = self else {
				completion?(NSError(ocError: .internal))
				jobDone()
				return
			}

			block(self, jobDone)
		})
	}

	// MARK: - Add/remove fixed components from consumers
	@discardableResult func addFixedComponents(from consumer: AccountConnectionConsumer) -> Bool {
		guard let core = self.core else { return false }

		if let messagePresenter = consumer.messagePresenter {
			core.messageQueue.add(presenter: messagePresenter)
		}

		if let progressSummarizerNotificationHandler = consumer.progressSummarizerNotificationHandler {
			progressSummarizer.addObserver(consumer, notificationBlock: progressSummarizerNotificationHandler)
		}

		return true
	}

	@discardableResult func removeFixedComponents(from consumer: AccountConnectionConsumer) -> Bool {
		guard let core = self.core else { return false }

		if consumer.progressSummarizerNotificationHandler != nil {
			progressSummarizer.removeObserver(consumer)
		}

		if let messagePresenter = consumer.messagePresenter {
			core.messageQueue.remove(presenter: messagePresenter)
		}

		return true
	}

	// MARK: - API
	public func add(consumer: AccountConnectionConsumer, completion: CompletionHandler?=nil) {
		queue(completion: completion) { (connection, jobDone) in
			OCSynchronized(connection.consumers) {
				connection.consumers.append(consumer)
			}

			// Add fixed components
			connection.addFixedComponents(from: consumer)

			// Initial calls to dynamic components
			consumer.statusObserver?.account(connection: connection, changedStatusTo: connection.status, initial: true)

			completion?(nil)
			jobDone()
		}
	}

	public func remove(consumer: AccountConnectionConsumer, completion: CompletionHandler?=nil) {
		queue(completion: completion) { (connection, jobDone) in
			// Remove fixed components
			self.removeFixedComponents(from: consumer)

			OCSynchronized(connection.consumers) {
				if let idx = connection.consumers.firstIndex(of: consumer) {
					connection.consumers.remove(at: idx)
				}
			}

			completion?(nil)
			jobDone()
		}
	}

	public func connect(consumer: AccountConnectionConsumer? = nil, completion: CompletionHandler? = nil) {
		queue(completion: completion) { (connection, jobDone) in
			guard connection.core == nil else {
				// Already has a core - nothing to do
				OnMainThread {
					completion?(nil)
				}
				jobDone()
				return
			}

			// No core yet - request one
			connection.status = .connecting

			OCCoreManager.shared.requestCore(for: connection.bookmark, setup: { (core, error) in
				// Setup core for AccountConnection
				if core != nil {
					connection.core = core

					// Install hooks
					core?.delegate = connection
					core?.busyStatusHandler = { [weak connection] (progress) in
						connection?.handleBusyStatus(progress: progress)
					}

					// Add fixed components from consumers
					connection.enumerateConsumers { consumer in
						connection.addFixedComponents(from: consumer)
					}

					// Observe .appProvider property
					if OCAppIdentity.shared.componentIdentifier == .app { // Only in the app
						connection.appProviderObservation = core?.observe(\OCCore.appProvider, options: .initial, changeHandler: { [weak connection] (core, change) in
							connection?.appProviderChanged(to: core.appProvider)
						})
					}

					// Remove skip available offline when user opens the bookmark
					core?.vault.keyValueStore?.storeObject(nil, forKey: .coreSkipAvailableOfflineKey)
				}
			}, completionHandler: { (core, error) in
				if error == nil {
					// Start FP standby in 5 seconds regardless of connnection status
					// (or below: after it's clear that authentication worked)
					OnBackgroundQueue(async: true, after: 5.0) { [weak connection] in
						connection?.startFPServiceStandbyIfNotRunning()
					}

					// Add default icons source to core's resource manager
					OnMainThread { [weak core] in
						if let core = core {
							core.vault.resourceManager?.add(ResourceSourceItemIcons(core: core))
						}
					}

					// Setup message selector
					if let core = core {
						let bookmarkUUID = core.bookmark.uuid

						self.messageSelector = MessageSelector(from: core.messageQueue, filter: { (message) in
							return (message.bookmarkUUID == bookmarkUUID) && !message.resolved
						}, provideGroupedSelection: true, provideSyncRecordIDs: true, handler: { [weak self] (messages, groups, syncRecordIDs) in
							self?.updateMessageSelectionWith(messages: messages, groups: groups, syncRecordIDs: syncRecordIDs)
						})
					}

					// Connected
					connection.status = .coreAvailable

					// Start showing connection status
					OnMainThread { [weak connection] () in
						connection?.connectionStatusObservation = core?.observe(\OCCore.connectionStatus, options: [.initial], changeHandler: { [weak connection] (_, _) in
							connection?.updateConnectionStatusSummary()

							if let connectionStatus = connection?.core?.connectionStatus,
							   connectionStatus == .online {
								// Start FP service standby after it's clear that authentication worked
								// (or above: after 5 seconds regardless of connnection status)
								connection?.startFPServiceStandbyIfNotRunning()
							}
						})
					}
				} else {
					connection.core = nil

					Log.error("Error requesting/starting core: \(String(describing: error))")
				}

				// Done
				OnMainThread {
					completion?(error)
				}
				jobDone()
			})
		}
	}

	public func disconnect(consumer: AccountConnectionConsumer? = nil, completion: CompletionHandler? = nil) {
		queue(completion: completion) { (connection, jobDone) in
			guard connection.core != nil else {
				// Has no core - nothing to do
				OnMainThread {
					completion?(nil)
				}
				jobDone()
				return
			}

			// Remove fixed components from consumers
			connection.enumerateConsumers { consumer in
				connection.removeFixedComponents(from: consumer)
			}

			// Remove App Provider action extensions
			connection.appProviderActionExtensions = nil

			connection.fpServiceStandby?.stop()

			// Return core
			OCCoreManager.shared.returnCore(for: self.bookmark, completionHandler: {
				connection.richStatus = nil
				connection.core = nil
				connection.status = .noCore

				OnMainThread {
					completion?(nil)
				}
				jobDone()
			})
		}
	}

	public typealias ConsumerEnumerator = (_ consumer: AccountConnectionConsumer) -> Void
	public typealias ConsumerConditionalEnumerator = (_ consumer: AccountConnectionConsumer) -> Bool // Return false to stop enumeration

	public func enumerateConsumers(with enumerator: ConsumerEnumerator) {
		OCSynchronized(self.consumers) {
			for consumer in self.consumers {
				enumerator(consumer)
			}
		}
	}

	public func enumerateConsumers(withConditional enumerator: ConsumerConditionalEnumerator) {
		OCSynchronized(self.consumers) {
			for consumer in self.consumers {
				if !enumerator(consumer) {
					// Enumerator returned false - stop enumeration
					break
				}
			}
		}
	}

	// MARK: - Delegation to consumers
	func handleBusyStatus(progress: Progress?) {
		OnMainThread(inline: true) {
			// Build rich status
			self.status = .busy
			self.richStatus = AccountConnectionRichStatus(kind: .status, progress: progress, status: .busy)

			// Distribute event to consumers
			self.enumerateConsumers { consumer in
				consumer.busyHandler?(progress)
			}
		}
	}

	// MARK: -
	var notificationPresenter : NotificationMessagePresenter?

	// MARK: - Progress Summarizer
	var progressSummarizer : ProgressSummarizer

	func setupProgressSummarizer() {
		// Set up progress summarizer
		progressSummarizer.addObserver(self) { [weak self] (summarizer, summary) in
			var useSummary : ProgressSummary = summary
			let prioritySummary : ProgressSummary? = summarizer.prioritySummary

			if (summary.progress == 1), (summarizer.fallbackSummary != nil) {
				useSummary = summarizer.fallbackSummary ?? summary
			}

			if let prioritySummary = prioritySummary {
				useSummary = prioritySummary
			}

			let autoCollapse = (((summarizer.fallbackSummary == nil) || (useSummary.progressCount == 0)) && (prioritySummary == nil)) // || (self?.allowProgressBarAutoCollapse ?? false)

			if let self = self {
				self.enumerateConsumers(with: { (consumer) in
					consumer.progressUpdateHandler?.account(connection: self, progressSummary: useSummary, autoCollapse: autoCollapse)
				})

				if autoCollapse {
					self.richStatus = nil
				} else {
					self.richStatus = AccountConnectionRichStatus(kind: .status, progressSummary: useSummary, status: self.status)
				}
			}
		}
	}

	func shutdownProgressSummarizer() {
		progressSummarizer.removeObserver(self)
	}

	// MARK: - App Provider updates
	var appProviderObservation: NSKeyValueObservation?

	var appProviderActionExtensions : [OCExtension]? {
		willSet {
			if let extensions = appProviderActionExtensions {
				for ext in extensions {
					OCExtensionManager.shared.removeExtension(ext)
				}
			}
		}

		didSet {
			if let extensions = appProviderActionExtensions {
				for ext in extensions {
					OCExtensionManager.shared.addExtension(ext)
				}
			}
		}
	}

	func appProviderChanged(to appProvider: OCAppProvider?) {
		var actionExtensions : [OCExtension] = []

		if let core = core {
			if let apps = core.appProvider?.apps {
				for app in apps {
					// Pre-load app icon
					if let appIconRequest = app.iconResourceRequest {
						core.vault.resourceManager?.start(appIconRequest)
					}

					// Create app-specific open-in-web-app action
					let openInWebAction = OpenInWebAppAction.createActionExtension(for: app, core: core)
					actionExtensions.append(openInWebAction)
				}
			}

			if let types = core.appProvider?.types {
				let creationTypes = types.filter({ type in
					return type.allowCreation
				})

				if creationTypes.count > 0 {
					// Pre-load document icons
					for type in creationTypes {
						if let typeIconRequest = type.iconResourceRequest {
							core.vault.resourceManager?.start(typeIconRequest)
						}
					}

					// Log.debug("Creation Types: \(String(describing: creationTypes))")
				}
			}
		}

		appProviderActionExtensions = actionExtensions
	}

	// MARK: - FileProvider Service pinging
	var fpServiceStandby : OCFileProviderServiceStandby?

	func startFPServiceStandbyIfNotRunning() {
		// Set up FP standby
		OCSynchronized(self) {
			if let core = core,
			   core.state == .starting || core.state == .running,
			   self.fpServiceStandby == nil {
				self.fpServiceStandby = OCFileProviderServiceStandby(core: core)
				self.fpServiceStandby?.start()
			}
		}
	}

	// MARK: - Connection status observation
	var connectionStatusObservation : NSKeyValueObservation?
	open var connectionStatus: OCCoreConnectionStatus?
	var connectionStatusSummary : ProgressSummary? {
		willSet {
			if newValue != nil {
				progressSummarizer.pushPrioritySummary(summary: newValue!)
			}
		}

		didSet {
			if oldValue != nil {
				progressSummarizer.popPrioritySummary(summary: oldValue!)
			}
		}
	}

	func updateConnectionStatusSummary() {
		var summary : ProgressSummary? = ProgressSummary(indeterminate: true, progress: 1.0, message: nil, progressCount: 1)

		connectionStatus = core?.connectionStatus

		if let connectionStatus = connectionStatus {
			var connectionShortDescription = core?.connectionStatusShortDescription

			connectionShortDescription = connectionShortDescription != nil ? (connectionShortDescription!.hasSuffix(".") ? connectionShortDescription! + " " : connectionShortDescription! + ". ") : ""

			switch connectionStatus {
				case .online:
					summary = nil
					status = .online

				case .connecting:
					summary?.message = "Connecting…".localized

				case .offline, .unavailable:
					summary?.message = String(format: "%@%@", connectionShortDescription!, "Contents from cache.".localized)
					// status = .coreAvailable
			}

			if connectionStatus == .online {
				// Connection switched to online - perform actions
				updateUserAvatar()
			}
		}

		connectionStatusSummary = summary
	}

	// MARK: - Actions to perform on connect
	private var userAvatarUpdated : Bool = false

	func updateUserAvatar() {
		if !userAvatarUpdated, let user = core?.connection.loggedInUser {
			// Update avatar on every connect
			userAvatarUpdated = true

			let avatarRequest = OCResourceRequestAvatar(for: user, maximumSize: OCAvatar.defaultSize, scale: 0, waitForConnectivity: true, changeHandler: { [weak self] request, error, ongoing, previousResource, newResource in
				if !ongoing,
				   let bookmarkUUID = self?.bookmark.uuid,
				   let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID),
				   let newResource = newResource as? OCViewProvider {
					bookmark.avatar = newResource
					OCBookmarkManager.shared.updateBookmark(bookmark)
				}
			})
			avatarRequest.lifetime = .singleRun

			core?.vault.resourceManager?.start(avatarRequest)
		}
	}

	// MARK: - Inline Message Center
	var messageSelector : MessageSelector?

	func updateMessageSelectionWith(messages: [OCMessage]?, groups : [MessageGroup]?, syncRecordIDs : Set<OCSyncRecordID>?) {
		OnMainThread {
			self.enumerateConsumers { consumer in
				consumer.messageUpdateHandler?.handleMessagesUpdates(messages: messages, groups: groups)
			}

			if syncRecordIDs != self.syncRecordIDsWithMessages {
				self.syncRecordIDsWithMessages = syncRecordIDs
			}
		}
	}

	var syncRecordIDsWithMessages : Set<OCSyncRecordID>? {
		didSet {
			if let core = core {
				NotificationCenter.default.post(name: .ClientSyncRecordIDsWithMessagesChanged, object: core)
			}
		}
	}
}

// MARK: - Core Delegate
extension AccountConnection : OCCoreDelegate {
	public func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		// Distribute event to consumers
		self.enumerateConsumers { consumer in
			// Send to all consumers until the first consumer indicates
			if consumer.coreErrorHandler?.account(connnection: self, handleError: error, issue: issue) == true {
				return false
			}

			return true
		}
	}
}
