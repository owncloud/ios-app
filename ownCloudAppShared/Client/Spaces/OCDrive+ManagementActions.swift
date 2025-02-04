//
//  OCDrive+ManagementActions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.02.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension OCDrive {
	static func create(with clientContext: ClientContext?) {
		guard let clientContext else { return }

		let createSpaceViewController = SpaceManagementViewController(clientContext: clientContext, completionHandler: { [weak clientContext] error, drive in
			if let error {
				OnMainThread {
					let alertController = ThemedAlertController(
						with: OCLocalizedString("Error creating space", nil),
						message: error.localizedDescription,
						okLabel: OCLocalizedString("OK", nil),
						action: nil)

					clientContext?.present(alertController, animated: true)
				}
			}
		})

		let navigationController = ThemeNavigationController(rootViewController: createSpaceViewController)
		clientContext.present(navigationController, animated: true)
	}

	public func disable(with clientContext: ClientContext?, completionHandler: OCCoreCompletionHandler?) {
		guard let core = clientContext?.core else { return }

		core.disableDrive(self, completionHandler: { error in
			if let error {
				OnMainThread {
					let alertController = ThemedAlertController(
						with: OCLocalizedFormat("Error disabling {{driveName}}", ["driveName" : self.name ?? OCLocalizedString("space", nil)]),
						message: error.localizedDescription,
						okLabel: OCLocalizedString("OK", nil),
						action: nil)

					clientContext?.present(alertController, animated: true)
				}

				completionHandler?(error)
			}
		})
	}

	func restore(with clientContext: ClientContext?) {
		guard let core = clientContext?.core else { return }

		core.restoreDrive(self, completionHandler: { error in
			if let error {
				OnMainThread {
					let alertController = ThemedAlertController(
						with: OCLocalizedFormat("Error enabling {{driveName}}", ["driveName" : self.name ?? OCLocalizedString("space", nil)]),
						message: error.localizedDescription,
						okLabel: OCLocalizedString("OK", nil),
						action: nil)

					clientContext?.present(alertController, animated: true)
				}
			}
		})
	}

	func delete(with clientContext: ClientContext?) {
		let alertController = ThemedAlertController(
			title: OCLocalizedFormat("Delete space \"{{driveName}}\"?", ["driveName" : self.name ?? OCLocalizedString("space", nil)]),
			message: OCLocalizedString("Are you sure you want to delete this space? This action cannot be undone.", nil),
			preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: OCLocalizedString("Delete", nil), style: .destructive, handler: { [weak clientContext] (_) in
			guard let core = clientContext?.core else { return }

			core.deleteDrive(self, completionHandler: { error in
				if let error {
					OnMainThread {
						let alertController = ThemedAlertController(
							with: OCLocalizedFormat("Error deleting {{driveName}}", ["driveName" : self.name ?? OCLocalizedString("space", nil)]),
							message: error.localizedDescription,
							okLabel: OCLocalizedString("OK", nil),
							action: nil)

						clientContext?.present(alertController, animated: true)
					}
				}
			})
		}))

		clientContext?.present(alertController, animated: true)
	}
}
