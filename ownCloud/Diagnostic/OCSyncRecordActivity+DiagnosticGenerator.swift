//
//  OCSyncRecordActivity+DiagnosticGenerator.swift
//  ownCloud
//
//  Created by Felix Schwarz on 29.07.20.
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

extension OCSyncRecordActivity : DiagnosticNodeGenerator {
	var isDiagnosticNodeGenerationAvailable : Bool {
		return VendorServices.shared.isBetaBuild
	}

	func provideDiagnosticNode(for context: OCDiagnosticContext, completion: @escaping (OCDiagnosticNode?, DiagnosticViewController.Style) -> Void) {
		if let core = context.core {
			core.vault.database?.retrieveSyncRecord(forID: self.recordID, completionHandler: { [weak core] (_, error, syncRecord) in
				if error == nil {
					if let syncRecordDiagnosticNodes = syncRecord?.diagnosticNodes(with: context), let allPipelines = core?.connection.allHTTPPipelines {
						var diagnosticNodes = syncRecordDiagnosticNodes
						var pipelineNodes : [OCDiagnosticNode] = []

						for pipeline in allPipelines {
							let nodes = pipeline.diagnosticNodes(with: context)
							pipelineNodes.append(OCDiagnosticNode.withLabel(pipeline.identifier, children: nodes))
						}

						diagnosticNodes.append(OCDiagnosticNode.withLabel("HTTP Requests", children: pipelineNodes))

						completion(OCDiagnosticNode.withLabel("Sync Record \(syncRecord?.recordID ?? 0)", children: diagnosticNodes), .hierarchical)
					}
				} else {
					Log.error("Error retrieving syncRecord \(self.recordID): \(String(describing: error))")
					completion(nil, .hierarchical)
				}
			})
		} else {
			completion(nil, .hierarchical)
		}
	}
}
