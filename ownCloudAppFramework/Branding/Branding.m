//
//  Branding.m
//  ownCloud
//
//  Created by Felix Schwarz on 21.01.21.
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

#import "Branding.h"

@interface Branding ()
{
	NSBundle *_appBundle;
	NSURL *_brandingPlistURL;
}
@end

@implementation Branding

+ (void)load
{
	// Provide hook to allow Swift extensions in the app to register defaults and metadata
	if ([self conformsToProtocol:@protocol(BrandingInitialization)])
	{
		[((Class<BrandingInitialization>)self) initializeBranding];
	}
}

+ (Branding *)sharedBranding
{
	static Branding *sharedBranding;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedBranding = [Branding new];
	});

	return (sharedBranding);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
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

		_appBundle = appBundle;
		_brandingPlistURL = [appBundle URLForResource:@"Branding" withExtension:@"plist"];

		_allowBranding = YES;

		NSData *brandingPlistData;

		if ((brandingPlistData = [NSData dataWithContentsOfURL:_brandingPlistURL]) != nil)
		{
			NSError *error = nil;

			if ((_brandingProperties = [NSPropertyListSerialization propertyListWithData:brandingPlistData options:NSPropertyListImmutable format:NULL error:&error]) == nil)
			{
				OCLogError(@"Error parsing %@: %@", _brandingPlistURL, error);
			}

			_brandingPropertiesFromLocalFile = _brandingPlistURL.isFileURL;
		}

		_legacyKeyPathsByClassSettingsKeys = @{
			BrandingKeyAppName 		: @"organizationName",
			BrandingKeyOrganizationName 	: @"organizationName"
		};

		// Provide hook to allow Swift extensions in the app to add legacy keys and more
		if ([self conformsToProtocol:@protocol(BrandingInitialization)])
		{
			[(id<BrandingInitialization>)self initializeSharedBranding];
		}
	}

	return (self);
}

- (void)registerLegacyKeyPath:(BrandingLegacyKeyPath)keyPath forClassSettingsKey:(OCClassSettingsKey)classSettingsKey;
{
	NSMutableDictionary<OCClassSettingsKey, BrandingLegacyKeyPath> *mutableLegacyKeyPathsByClassSettingsKeys = nil;

	if (![_legacyKeyPathsByClassSettingsKeys isKindOfClass:NSMutableDictionary.class])
	{
		_legacyKeyPathsByClassSettingsKeys = [_legacyKeyPathsByClassSettingsKeys mutableCopy];
	}

	mutableLegacyKeyPathsByClassSettingsKeys = (NSMutableDictionary<OCClassSettingsKey, BrandingLegacyKeyPath> *)_legacyKeyPathsByClassSettingsKeys;

	mutableLegacyKeyPathsByClassSettingsKeys[classSettingsKey] = keyPath;
}

- (NSString *)appName
{
	return ([self computedValueForClassSettingsKey:BrandingKeyAppName]);
}

- (NSString *)organizationName
{
	return ([self computedValueForClassSettingsKey:BrandingKeyOrganizationName]);
}

- (nullable UIImage *)brandedImageNamed:(BrandingImageName)imageName
{
	return ([UIImage imageNamed:imageName inBundle:self.appBundle compatibleWithTraitCollection:nil]);
}

- (nullable id)computedValueForClassSettingsKey:(OCClassSettingsKey)classSettingsKey
{
	id value = nil;

	if (classSettingsKey == nil) { return(nil); }

	if (!self.allowBranding)
	{
		// If branding is not allowed, return default value
		return ([self.class defaultSettingsForIdentifier:OCClassSettingsIdentifierBranding][classSettingsKey]);
	}

	// Legacy support: try legacy key from Branding.plist
	BrandingLegacyKey legacyKeyPath = _legacyKeyPathsByClassSettingsKeys[classSettingsKey];

	if (legacyKeyPath != nil)
	{
		value = [_brandingProperties valueForKeyPath:legacyKeyPath];
	}

	if (value == nil)
	{
		// Retrieve value from class settings - this includes
		// BrandingClassSettingsSource, which grabs values from regular keys in
		// Branding.plist at this point
		value = [self classSettingForOCClassSettingsKey:classSettingsKey];
	}

	return (value);
}

- (nullable NSURL *)urlForClassSettingsKey:(OCClassSettingsKey)settingsKey
{
	NSString *urlString;

	if ((urlString = [self computedValueForClassSettingsKey:settingsKey]) != nil)
	{
		if (urlString.length > 0)
		{
			return ([NSURL URLWithString:urlString]);
		}
	}

	return (nil);
}

#pragma mark - Class Settings
+ (OCClassSettingsIdentifier)classSettingsIdentifier
{
	return (OCClassSettingsIdentifierBranding);
}

+ (NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	return (@{
	});
}

+ (OCClassSettingsMetadataCollection)classSettingsMetadata
{
	return (@{
		// App Name
		BrandingKeyAppName : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"App name to use throughout the app.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Branding",
		},

		// Organization Name
		BrandingKeyOrganizationName : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription 	: @"Organization name to use throughout the app.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Branding",
		}
	});
}

@end

OCClassSettingsIdentifier OCClassSettingsIdentifierBranding = @"branding";

OCClassSettingsKey BrandingKeyAppName = @"app-name"; 			// Legacy Branding Key: organizationName
OCClassSettingsKey BrandingKeyOrganizationName = @"organization-name"; 	// Legacy Branding Key: organizationName
