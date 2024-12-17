//
//  OCFileProviderSettings.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 25.09.22.
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

#import "OCFileProviderSettings.h"
#import "ownCloudApp/ConfidentialManager.h"

@implementation OCFileProviderSettings

+ (OCClassSettingsIdentifier)classSettingsIdentifier
{
	return (OCClassSettingsIdentifierFileProvider);
}

+ (nullable NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(nonnull OCClassSettingsIdentifier)identifier {
	return (@{
		OCClassSettingsKeyFileProviderBrowseable : @(YES)
	});
}

+ (OCClassSettingsMetadataCollection)classSettingsMetadata
{
	return (@{
		// FileProvider
		OCClassSettingsKeyFileProviderBrowseable : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription 	: @"Controls whether the account content is available to other apps via File Provider / Files.app.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"FileProvider",
		}
	});
}

+ (BOOL)browseable
{
	if ([[ConfidentialManager sharedConfidentialManager] allowOverwriteConfidentialMDMSettings] == false) {
		return false;
	}
	
	return ([([self classSettingForOCClassSettingsKey:OCClassSettingsKeyFileProviderBrowseable]) boolValue]);
}

@end

OCClassSettingsIdentifier OCClassSettingsIdentifierFileProvider = @"fileprovider";
OCClassSettingsKey OCClassSettingsKeyFileProviderBrowseable = @"browseable";
