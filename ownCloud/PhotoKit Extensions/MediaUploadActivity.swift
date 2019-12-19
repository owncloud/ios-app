//
//  MediaUploadActivity.swift
//  ownCloud
//
//  Created by Michael Neuwert on 19.11.2019.
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

import ownCloudSDK

class MediaUploadActivity : OCActivity {

	var isCancelled: Bool {
		if let progress = self.progress {
			return progress.isCancelled
		}
		return false
	}

	init(identifier: OCActivityIdentifier, assetCount:Int) {
		super.init(identifier: identifier)
		self.isCancellable = true
		self.localizedDescription = "Media import".localized

		if assetCount <= 0 {
			self.progress = Progress.indeterminate()
		} else {
			self.progress = Progress(totalUnitCount: Int64(assetCount))
			self.updateStatusMessage()
		}
	}

	public func updateAfterSingleFinishedUpload() {
		guard let progress = self.progress else { return }
		guard progress.isIndeterminate == false else { return }

		self.progress?.completedUnitCount += 1
		self.updateStatusMessage()
	}

	// MARK: - Private helper methods

	private func updateStatusMessage() {
		if let progress = self.progress, progress.isIndeterminate == false {
			let total = progress.totalUnitCount
			let current = progress.completedUnitCount
			self.localizedStatusMessage = String(format: "%@ of %@".localized, "\(current)", "\(total)")
		}
	}
}
