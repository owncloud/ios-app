//
//  BrandingClassSettingsSource.m
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 11.09.20.
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

#import "BrandingClassSettingsSource.h"
#import "Branding.h"

@implementation BrandingClassSettingsSource

+ (void)load
{
	[OCClassSettings.sharedSettings insertSource:[BrandingClassSettingsSource new] before:OCClassSettingsSourceIdentifierUserPreferences after:nil];
}

- (OCClassSettingsSourceIdentifier)settingsSourceIdentifier
{
	return (OCClassSettingsSourceIdentifierBranding);
}

- (NSDictionary <OCClassSettingsFlatIdentifier, id> *)flatSettingsDictionary
{
	NSDictionary <OCClassSettingsFlatIdentifier, id> *flatSettingsDict = Branding.sharedBranding.brandingProperties;

	if (Branding.sharedBranding.brandingPropertiesFromLocalFile)
	{
		// Support "Configuration" dictionary only for branding properties coming from (legacy) local files
		NSDictionary <OCClassSettingsFlatIdentifier, id> *legacyConfiguration = [flatSettingsDict objectForKey:@"Configuration"];

		// If a "Configuration" dictionary is provided, use it as base layer, but copy the brandingProperties on top
		if (legacyConfiguration != nil)
		{
			NSMutableDictionary <OCClassSettingsFlatIdentifier, id> *combinedSettings;

			if ((combinedSettings = [legacyConfiguration mutableCopy]) != nil)
			{
				[combinedSettings addEntriesFromDictionary:flatSettingsDict];

				combinedSettings[@"Configuration"] = nil; // Remove "Configuration"

				flatSettingsDict = combinedSettings;
			}
		}
	}
	else
	{
		// Branding properties from remote location - TOOD: strip anything but OCClassSettingsSourceIdentifierBranding parameters
	}

	return (flatSettingsDict);
}

@end

OCClassSettingsSourceIdentifier OCClassSettingsSourceIdentifierBranding = @"branding";
