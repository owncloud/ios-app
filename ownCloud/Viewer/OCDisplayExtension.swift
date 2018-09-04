//
//  OCDisplayExtension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 03/09/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class OCDisplayExtension: OCExtension {

	init(identifier: OCExtensionIdentifier!, type: OCExtensionType!, location: OCExtensionLocation!, features: [String : Any]!, objectProvider: @escaping OCExtensionObjectProvider) {

		super.init()
		self.identifier = identifier
		self.type = type
		self.locations = [location]
		self.features = features
		self.objectProvider = objectProvider
	}

	override func matchesContext(_ context: OCExtensionContext!) -> OCExtensionPriority {

		var matchPriority: OCExtensionPriority = .noMatch

		if context.location.type == self.type {
			matchPriority = .typeMatch

			if context.location.identifier != nil, locations.count > 0 {
				var matchedLocation = false

				for location in locations {
					if location.identifier == context.location.identifier {

						guard let displayLocation = location as? OCDisplayExtensionLocation, let contextDisplayLocation = context.location as? OCDisplayExtensionLocation else {
							return OCExtensionPriority.noMatch
						}

						for mimeType in displayLocation.supportedMimeTypes {
							if contextDisplayLocation.supportedMimeTypes.contains(mimeType) {
								matchedLocation = true
								matchPriority = .locationMatch
								break
							}
						}
					}
				}

				if !matchedLocation {
					return OCExtensionPriority.noMatch
				}
			}

			if context.requirements != nil, context.requirements.count > 0 {
				var allRequirementsMet = true

				if self.features == nil {
					return OCExtensionPriority.noMatch
				}

				for requirementKey in context.requirements {
					let feature = features[requirementKey.key] as AnyObject
					let requirement = context.requirements[requirementKey.key] as AnyObject
					if feature.isEqual(requirement) {
						allRequirementsMet = false
					}
				}

				if !allRequirementsMet {
					return OCExtensionPriority.noMatch
				}

				matchPriority = .requirementMatch
			}

			if priority != .noMatch {
				matchPriority = priority
			} else {
				if context.preferences != nil, context.preferences.count > 0, self.features != nil {
					for preferencekey in context.preferences {
						let feature = features[preferencekey.key] as AnyObject
						let requirement = context.preferences[preferencekey.key] as AnyObject
						if feature.isEqual(requirement) {
							// TODO : Talk with felix because this is not allowed in Swift.
							//matchPriority += Float(OCExtensionPriority.featureMatchPlus.rawValue)
						}
					}
				}
			}
		}
		return matchPriority
	}
}
