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

INCLUDE_IN_CLASS_SETTINGS_SNAPSHOTS(Branding)

+ (void)load
{
	// Provide hook to allow Swift extensions in the app to register defaults and metadata
	if ([self conformsToProtocol:@protocol(BrandingInitialization)])
	{
		if (@available(iOS 13, *))
		{
			[((Class<BrandingInitialization>)self) initializeBranding];
		}
		else
		{
			// BEGIN: Workaround for iOS 12 Swift crash bug - this code is usually in +initializeBranding in ownCloudAppShared.framework - remove when dropping iOS 12 support
			[self registerOCClassSettingsDefaults:@{
				@"url-documentation" 	: @"https://doc.owncloud.com/ios-app/",
				@"url-help" 	  	: @"https://owncloud.com/docs-guides/",
				@"url-privacy" 	  	: @"https://owncloud.org/privacy-policy/",
				@"url-terms-of-use" 	: @"https://raw.githubusercontent.com/owncloud/ios-app/master/LICENSE",

				@"send-feedback-address" : @"ios-app@owncloud.com",

				@"can-add-account" : @(YES),
				@"can-edit-account" : @(YES),
				@"enable-review-prompt" : @(NO)
			} metadata:@{
				@"url-documentation" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeURLString,
					OCClassSettingsMetadataKeyDescription 	: @"URL to documentation for the app. Opened when selecting \"Documentation\" in the settings.",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
					OCClassSettingsMetadataKeyCategory	: @"Branding"
				},

				@"url-help" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeURLString,
					OCClassSettingsMetadataKeyDescription 	: @"URL to help for the app. Opened when selecting \"Help\" in the settings.",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
					OCClassSettingsMetadataKeyCategory	: @"Branding"
				},

				@"url-privacy" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeURLString,
					OCClassSettingsMetadataKeyDescription 	: @"URL to privacy information for the app. Opened when selecting \"Privacy\" in the settings.",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
					OCClassSettingsMetadataKeyCategory	: @"Branding"
				},

				@"url-terms-of-use" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeURLString,
					OCClassSettingsMetadataKeyDescription 	: @"URL to terms of use for the app. Opened when selecting \"Terms Of Use\" in the settings.",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
					OCClassSettingsMetadataKeyCategory	: @"Branding"
				},

				@"send-feedback-address" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeString,
					OCClassSettingsMetadataKeyDescription	: @"Email address to send feedback to. Set to `null` to disable this feature.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				},

				@"can-add-account" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
					OCClassSettingsMetadataKeyDescription	: @"Controls whether the user can add accounts.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				},

				@"can-edit-account" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
					OCClassSettingsMetadataKeyDescription	: @"Controls whether the user can edit accounts.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				},

				@"enable-review-prompt" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
					OCClassSettingsMetadataKeyDescription	: @"Controls whether the app should prompt for an App Store review.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				},

				@"profile-definitions" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeDictionaryArray,
					OCClassSettingsMetadataKeyDescription	: @"Array of dictionaries, each specifying a static profile.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				},

				@"theme-generic-colors" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeDictionary,
					OCClassSettingsMetadataKeyDescription	: @"Dictionary defining generic colors that can be used in the definitions.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				},

				@"theme-definitions" : @{
					OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeDictionaryArray,
					OCClassSettingsMetadataKeyDescription	: @"Array of dictionaries, each specifying a theme.",
					OCClassSettingsMetadataKeyCategory	: @"Branding",
					OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced
				}
			}];
			// END: Workaround for iOS 12 Swift crash bug - this code is usually in +initializeBranding in ownCloudAppShared.framework - remove when dropping iOS 12 support
		}
	}

	// Provide hook to allow Swift extensions in the app to register defaults and metadata
	if ([self conformsToProtocol:@protocol(StaticProfileBridge)])
	{
		[((Class<StaticProfileBridge>)self) initializeStaticProfileBridge];
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
			else
			{
				// Expand "flat" syntax
				_brandingProperties = [_brandingProperties expandedDictionary];
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

		// Set app.name localization variable to branded name
		[OCLocaleFilterVariables.shared setVariable:@"app.name" value:self.appDisplayName];
	}

	return (self);
}

- (void)registerUserDefaultsDefaults
{
	// Register user defaults
	NSDictionary *userDefaultsDefaults;
	if ((userDefaultsDefaults = self.userDefaultsDefaultValues) != nil)
	{
		[OCAppIdentity.sharedAppIdentity.userDefaults registerDefaults:userDefaultsDefaults];
	}
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

- (NSString *)appDisplayName
{
	NSString *appName;

	if ((appName = self.appName) != nil) { return (appName); }
	if ((appName = self.organizationName) != nil) { return (appName); }
	if ((appName = OCAppIdentity.sharedAppIdentity.appDisplayName) != nil) { return (appName); }

	return (@"ownCloud");
}

- (NSDictionary *)userDefaultsDefaultValues
{
	return ([self computedValueForClassSettingsKey:BrandingKeyUserDefaultsDefaultValues]);
}

- (NSArray<BrandingFileImportMethod> *)disabledImportMethods
{
	return ([self computedValueForClassSettingsKey:BrandingKeyDisabledImportMethods]);
}

- (BOOL)isImportMethodAllowed:(BrandingFileImportMethod)importMethod
{
	if ((importMethod != nil) && [self.disabledImportMethods containsObject:importMethod])
	{
		return (NO);
	}

	return (YES);
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
		NSURL *url = nil;

		if ((url = OCTypedCast(urlString, NSURL)) != nil)
		{
			// urlString is already an NSURL - return it, unless it is empty
			if (url.absoluteString.length > 0)
			{
				return (url);
			}
		}
		else if (urlString.length > 0)
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
		},

		// Disabled import methods
		BrandingKeyDisabledImportMethods : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeStringArray,
			OCClassSettingsMetadataKeyDescription 	: @"List of disabled import methods that can't be used.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusSupported,
			OCClassSettingsMetadataKeyCategory	: @"Branding",
			OCClassSettingsMetadataKeyPossibleValues : @{
				BrandingFileImportMethodOpenWith	: @"Disallow import through \"Open with\"",
				BrandingFileImportMethodShareExtension  : @"Disallow import through the Share Extension",
				BrandingFileImportMethodFileProvider	: @"Disallow import through the File Provider (Files.app)"
			}
		},

		// User Defaults
		BrandingKeyUserDefaultsDefaultValues : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeDictionary,
			OCClassSettingsMetadataKeyDescription 	: @"Default values for user defaults. Allows overriding default settings.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Branding"
		}
	});
}

@end

OCClassSettingsIdentifier OCClassSettingsIdentifierBranding = @"branding";

BrandingKey BrandingKeyAppName = @"app-name";
BrandingKey BrandingKeyOrganizationName = @"organization-name"; 	// Legacy Branding Key: organizationName
BrandingKey BrandingKeyDisabledImportMethods = @"disabled-import-methods";
BrandingKey BrandingKeyUserDefaultsDefaultValues = @"user-defaults-default-values";

BrandingFileImportMethod BrandingFileImportMethodOpenWith = @"open-with";
BrandingFileImportMethod BrandingFileImportMethodShareExtension = @"share-extension";
BrandingFileImportMethod BrandingFileImportMethodFileProvider = @"file-provider";
