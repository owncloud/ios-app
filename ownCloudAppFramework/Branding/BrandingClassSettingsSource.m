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

@implementation BrandingClassSettingsSource

+ (void)load
{
	[OCClassSettings.sharedSettings insertSource:[BrandingClassSettingsSource new] before:OCClassSettingsSourceIdentifierUserPreferences after:nil];
}

+ (NSURL *)brandingURL
{
	NSBundle *appBundle;

	if ((appBundle = NSBundle.mainBundle) != nil)
	{
		if ([appBundle.bundleURL.pathExtension isEqual:@"appex"])
		{
			// Find container app bundle (ownCloud.app/PlugIns/Extension.appex)
			appBundle = [NSBundle bundleWithURL:appBundle.bundleURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent];
		}
	}

	return ([appBundle URLForResource:@"Branding" withExtension:@"plist"]);
}

+ (NSDictionary<NSString *, id> *)brandingProperties
{
	static NSDictionary<NSString *, id> *brandingProperties;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSData *brandingPlistData;

		if ((brandingPlistData = [NSData dataWithContentsOfURL:BrandingClassSettingsSource.brandingURL]) != nil)
		{
			NSError *error = nil;

			if ((brandingProperties = [NSPropertyListSerialization propertyListWithData:brandingPlistData options:NSPropertyListImmutable format:NULL error:&error]) == nil)
			{
				OCLogError(@"Error parsing %@: %@", BrandingClassSettingsSource.brandingURL, error);
			}
		}
	});

	return (brandingProperties);
}

- (OCClassSettingsSourceIdentifier)settingsSourceIdentifier
{
	return (OCClassSettingsSourceIdentifierBranding);
}

- (NSDictionary <NSString *, id> *)flatSettingsDictionary
{
	return ([BrandingClassSettingsSource.brandingProperties objectForKey:@"Configuration"]);
}

@end

OCClassSettingsSourceIdentifier OCClassSettingsSourceIdentifierBranding = @"branding";
