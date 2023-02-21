//
//  OCLocation+Breadcrumbs.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 26.01.23.
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
import ownCloudSDK

public extension OCActionPropertyKey {
	static let location = OCActionPropertyKey(rawValue: "location")
}

public extension OCLocation {
	func displayName(in context: ClientContext?) -> String {
		switch type {
			case .drive:
				if let core = context?.core, let driveID, let drive = core.drive(withIdentifier: driveID), let driveName = drive.name {
					return driveName
				}
				return "Space".localized

			case .folder, .file:
				if driveID == nil, isRoot {
					// OC 10 root folder
					return "Files".localized
				}

				if let lastPathComponent {
					return lastPathComponent
				}

			case .account:
				if let bookmarkUUID, let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
					return bookmark.displayName ?? bookmark.shortName
				}

			default: break
		}

		return ""
	}

	func displayIcon(in context: ClientContext?, forSidebar: Bool = false) -> UIImage? {
		switch type {
			case .drive:
				if let core = context?.core, let driveID, let drive = core.drive(withIdentifier: driveID), let specialType = drive.specialType {
					switch specialType {
						case .personal:
							return OCSymbol.icon(forSymbolName: forSidebar ? "person" : "person.fill")

						case .shares:
							return OCSymbol.icon(forSymbolName: forSidebar ? "arrowshape.turn.up.left" : "arrowshape.turn.up.left.fill")

						default: break
					}
				}

				return OCSymbol.icon(forSymbolName: forSidebar ? "square.grid.2x2" : "square.grid.2x2.fill")

			case .folder:
				return OCSymbol.icon(forSymbolName: forSidebar ? "folder" : "folder.fill")

			case .file:
				return OCSymbol.icon(forSymbolName: forSidebar ? "doc" : "doc.fill")

			default: break
		}

		return nil
	}

	func breadcrumbs(in clientContext: ClientContext, includeServerName: Bool = true, includeDriveName: Bool = true) -> [OCAction] {
		var breadcrumbs: [OCAction] = []
		var currentLocation = self

		func addCrumb(title: String?, icon: UIImage?, location: OCLocation? = nil) {
			var actionBlock: OCActionBlock?

			if let location {
				actionBlock = { [weak clientContext] (action, options, completion) in
					if let context = (options?[.clientContext] as? ClientContext) ?? clientContext {
						_ = (location as DataItemSelectionInteraction).openItem?(from: nil, with: context, animated: true, pushViewController: true, completion: { (success) in
							completion(success ? nil : NSError(ocError: .internal))
						})
					}
				}
			}

			let action = OCAction(title: title ?? "?", icon: icon, action: actionBlock)
			action.properties[.location] = location

			breadcrumbs.insert(action, at: 0)
		}

		// Location in reverse
		if currentLocation.type == .folder {
			while !currentLocation.isRoot, currentLocation.path != nil {
				if currentLocation.type == .folder {
					addCrumb(title: currentLocation.displayName(in: clientContext), icon: currentLocation.displayIcon(in: clientContext), location: currentLocation)
				}

				if let parent = currentLocation.parent {
					currentLocation = parent
				} else {
					break
				}
			}
		}

		// Drive name
		if let driveID = self.driveID, includeDriveName {
			let location = OCLocation(driveID: driveID, path: "/")
			addCrumb(title: location.displayName(in: clientContext), icon: location.displayIcon(in: clientContext), location: location)
		}

		// Server name
		if let bookmark = clientContext.core?.bookmark, includeServerName {
			addCrumb(title: bookmark.displayName ?? bookmark.shortName, icon: OCSymbol.icon(forSymbolName: "server.rack"), location: (self.driveID == nil) ? OCLocation.legacyRoot : nil)
		}

		return breadcrumbs
	}
}

extension OCLocation {
	static func composeSegments(breadcrumbs: [OCAction], in clientContext: ClientContext, segmentConfigurator: ((_ breadcrumb: OCAction, _ segment: SegmentViewItem) -> Void)? = nil) -> [SegmentViewItem] {
		var segments: [SegmentViewItem] = []

		for breadcrumb in breadcrumbs {
			if !segments.isEmpty {
				let seperatorSegment = SegmentViewItem(with: OCSymbol.icon(forSymbolName: "chevron.right"))
				seperatorSegment.insets.leading = 0
				seperatorSegment.insets.trailing = 0
				segments.append(seperatorSegment)
			}

			let segment = SegmentViewItem(with: breadcrumb.icon, title: breadcrumb.title, style: .plain, titleTextStyle: .footnote)

			if let segmentConfigurator {
				segmentConfigurator(breadcrumb, segment)
			}

			segments.append(segment)
		}

		segments.last?.titleTextWeight = .semibold
		segments.last?.gestureRecognizers = nil

		segments.first?.insets.leading = 0
		segments.last?.insets.trailing = 0

		return segments
	}
}
