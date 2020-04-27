//
//  CardIssueMessagePresenter.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.03.20.
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
import ownCloudSDK

class CardIssueMessagePresenter: OCMessagePresenter {

	typealias CardIssueMessagePresenterViewControllerPresenter = (UIViewController) -> Void

	var bookmarkUUID : OCBookmarkUUID
	var presenter : CardIssueMessagePresenterViewControllerPresenter

	var isShowingCard : Bool = false
	var oneCardLimit : Bool

	init(with bookmarkUUID: OCBookmarkUUID, limitToSingleCard: Bool, presenter: @escaping CardIssueMessagePresenterViewControllerPresenter) {
		self.bookmarkUUID = bookmarkUUID
		self.oneCardLimit = limitToSingleCard
		self.presenter = presenter

		super.init()

		self.identifier = OCMessagePresenterIdentifier(rawValue: "card.\(bookmarkUUID.uuidString)")
	}

	override func presentationPriority(for message: OCMessage) -> OCMessagePresentationPriority {
		if message.syncIssue != nil, let messageBookmarkUUID = message.bookmarkUUID, let bookmarkUUID = bookmarkUUID as UUID?, messageBookmarkUUID == bookmarkUUID, !oneCardLimit || (oneCardLimit && !isShowingCard) {
			return .high
		}

		return .wontPresent
	}

	override func present(_ message: OCMessage, completionHandler: @escaping (OCMessagePresentationResult, OCSyncIssueChoice?) -> Void) {
		var options : [AlertOption] = []

		if let choices = message.syncIssue?.choices {
			for choice in choices {
				let option = AlertOption(label: choice.label, type: choice.type, handler: { [weak self] (_, _) in
					self?.isShowingCard = false
					completionHandler(.didPresent, choice)
				})

				options.append(option)
			}
		}

		if options.count == 0 {
			options.append(AlertOption(label: "OK".localized, type: .default, handler: { [weak self] (_, _) in
				self?.isShowingCard = false
				completionHandler(.didPresent, nil)
			}))
		}

		if let syncIssue = message.syncIssue {
			var localizedHeader : String?

			if let messageBookmarkUUID = message.bookmarkUUID, (bookmarkUUID as UUID) != messageBookmarkUUID {
				if let messageBookmark = OCBookmarkManager.shared.bookmark(for: messageBookmarkUUID) {
					localizedHeader = messageBookmark.shortName
				}
			}

			let alertViewController = AlertViewController(localizedHeader: localizedHeader, localizedTitle: syncIssue.localizedTitle, localizedDescription: syncIssue.localizedDescription ?? "", options: options, dismissHandler: { [weak self] in
				self?.isShowingCard = false
				completionHandler(.didPresent, nil)
			})

			self.isShowingCard = true

			self.presenter(alertViewController)
		}
	}
}
