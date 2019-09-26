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
	func exportVideo(targetURL:URL, type:AVFileType, completion:@escaping (_ success:Bool) -> Void) {
		if self.isExportable {

			let preset = AVAssetExportPresetHighestQuality

			AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: self, outputFileType: type, completionHandler: { (isCompatible) in
				if !isCompatible {
					completion(false)
				}})

			guard let export = AVAssetExportSession(asset: self, presetName: preset) else {
				completion(false)
				return
			}

			export.outputFileType = type
			export.outputURL = targetURL
			export.exportAsynchronously {
				completion( export.status == .completed )
			}
		} else {
			completion(false)
		}
	}
}
