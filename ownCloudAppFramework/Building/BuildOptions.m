//
//  BuildOptions.m
//  ownCloud
//
//  Created by Felix Schwarz on 15.11.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2021, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "BuildOptions.h"

OCClassSettingsIdentifier OCClassSettingsIdentifierBuildOptions = @"build";

OCClassSettingsKey	  OCClassSettingsKeyBuildFlags = @"flags";
OCClassSettingsKey	  OCClassSettingsKeyCustomAppScheme = @"custom-app-scheme";
OCClassSettingsKey	  OCClassSettingsKeyCustomAuthScheme = @"custom-auth-scheme";
OCClassSettingsKey	  OCClassSettingsKeyAppGroupIdentifier = @"app-group-identifier";
OCClassSettingsKey	  OCClassSettingsKeyOCAppGroupIdentifier = @"oc-app-group-identifier";

@implementation BuildOptions

+ (void)load
{
	// Make sure the class is loaded
	[self classSettingsIdentifier];
}

+ (OCClassSettingsIdentifier)classSettingsIdentifier
{
	return (OCClassSettingsIdentifierBuildOptions);
}

+ (NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	return(@{
		OCClassSettingsKeyCustomAppScheme  : @"owncloud",
		OCClassSettingsKeyCustomAuthScheme : @"oc"
	});
}

+ (OCClassSettingsMetadataCollection)classSettingsMetadata
{
	return (@{
		// build.flags
		OCClassSettingsKeyBuildFlags : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"A set of space separated flags to customize the build. Must be provided in Branding.plist at build time. For documentation, please see doc/BUILD_CUSTOMIZATION.md.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Build",
		},

		// build.custom-app-scheme
		OCClassSettingsKeyCustomAppScheme : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"Name of the URL scheme to use for private links. Must be provided in Branding.plist at build time. For documentation, please see doc/BUILD_CUSTOMIZATION.md.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Build",
		},

		// build.custom-app-scheme
		OCClassSettingsKeyCustomAuthScheme : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"Name of the URL scheme to use for OAuth2/OIDC authentication. Must be provided in Branding.plist at build time. The authentication redirect URI parameters must also be changed accordingly in Branding.plist and on the server side. For documentation, please see doc/BUILD_CUSTOMIZATION.md.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Build",
		},

		// build.app-group-identifier
		OCClassSettingsKeyAppGroupIdentifier : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"Set a custom app group identifier via Branding.plist parameter. This value will be set by fastlane. Changes OCAppGroupIdentifier, OCKeychainAccessGroupIdentifier and updates other, directly signing-relevant parts of the Info.plist. With this value set, fastlane needs the provisioning profiles and certificate with the app group identifier. This is needed, if a customer is using an own resigning script which does not handle setting the app group identifier.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Build",
		},

		// build.oc-app-group-identifier
		OCClassSettingsKeyOCAppGroupIdentifier : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"Set a custom app group identifier via Branding.plist parameter. This value will be set by fastlane. Changes OCAppGroupIdentifier, OCKeychainAccessGroupIdentifier only. Fastlane does not need the provisioning profile and certificate with the given app group identifer. Needs resigning with the correct provisioning profile and certificate. This is needed, if a customer is using an own resigning script which does not handle setting the app group identifier.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Build",
		},
	});
}

@end
