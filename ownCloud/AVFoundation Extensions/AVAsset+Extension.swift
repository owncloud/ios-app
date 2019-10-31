//
//  AVAsset+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 17.07.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import AVFoundation

extension AVAsset {
	func exportVideo(targetURL:URL, type:AVFileType) -> Bool {
		if self.isExportable {
			let group = DispatchGroup()
			let preset = AVAssetExportPresetHighestQuality
			var compatiblePreset = false
			var exportSuccess = false

			group.enter()
			AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: self, outputFileType: type, completionHandler: { (isCompatible) in
				compatiblePreset = isCompatible
				group.leave()
			})

			if compatiblePreset {
				guard let export = AVAssetExportSession(asset: self, presetName: preset) else {
					return false
				}
				// Configure export session
				export.outputFileType = type
				export.outputURL = targetURL

				// Start export
				group.enter()
				export.exportAsynchronously {
					exportSuccess = (export.status == .completed)
					group.leave()
				}
			}

			group.wait()
			return exportSuccess
		}

		return false
	}
}
