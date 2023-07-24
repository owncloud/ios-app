//
//  AppLockSettings.m
//  AppLockSettings
//
//  Created by Felix Schwarz on 09.09.21.
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

#import "AppLockSettings.h"
#import "Branding.h"
#import <LocalAuthentication/LocalAuthentication.h>

@implementation AppLockSettings

+ (instancetype)sharedAppLockSettings
{
	static dispatch_once_t onceToken;
	static AppLockSettings *sharedAppLockSettings;

	dispatch_once(&onceToken, ^{
		sharedAppLockSettings = [AppLockSettings new];
	});

	return (sharedAppLockSettings);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		_userDefaults = OCAppIdentity.sharedAppIdentity.userDefaults;
	}

	return (self);
}

#pragma mark - Class settings
+ (OCClassSettingsIdentifier)classSettingsIdentifier
{
	return (OCClassSettingsIdentifierPasscode);
}

+ (NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	return (@{
		OCClassSettingsKeyPasscodeEnforced : @(NO),
		OCClassSettingsKeyRequiredPasscodeDigits : @(NO),
		OCClassSettingsKeyRequiredPasscodeDigits : @(4),
		OCClassSettingsKeyMaximumPasscodeDigits : @(6),
		OCClassSettingsKeyPasscodeUseBiometricalUnlock : @(NO),
		OCClassSettingsKeyPasscodeShareSheetBiometricalUnlockByApp : @{
			@"default" : @{
				@"allow" : @(YES)
			},

			// For unknown reasons invoking biometric authentication from the
			// share sheet in Boxer leads to dismissal of the entire share sheet,
			// so (as of July 2022) we hardcode it as an exception here
			@"com.air-watch.boxer" : @{
				@"allow" : @(NO)
			}
		}
	});
}

+ (OCClassSettingsMetadataCollection)classSettingsMetadata
{
	return (@{
		OCClassSettingsKeyPasscodeEnforced : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription 	: @"Controls wether the user MUST establish a passcode upon app installation.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		},
		
		OCClassSettingsKeyRequiredPasscodeDigits : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription 	: @"Controls wether the user MUST establish a passcode upon app installation, if NO device passcode protection is set.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		},
		
		OCClassSettingsKeyRequiredPasscodeDigits : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription 	: @"Controls how many passcode digits are at least required for passcode lock.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		},

		OCClassSettingsKeyMaximumPasscodeDigits : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription 	: @"Controls how many passcode digits are maximal possible for passcode lock.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		},

		OCClassSettingsKeyPasscodeLockDelay : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription 	: @"Number of seconds before the lock snaps and the passcode is requested again.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		},

		OCClassSettingsKeyPasscodeUseBiometricalUnlock	: @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription	: @"Controls wether the biometrical unlock will be enabled automatically.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		},

		OCClassSettingsKeyPasscodeShareSheetBiometricalUnlockByApp : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeDictionary,
			OCClassSettingsMetadataKeyDescription	: @"Controls the  biometrical unlock availability in the share sheet, with per-app level control.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Passcode"
		}
	});
}

#pragma mark - Settings
- (BOOL)lockEnabled
{
	return ([_userDefaults boolForKey:@"applock-lock-enabled"]);
}

- (void)setLockEnabled:(BOOL)lockEnabled
{
	[_userDefaults setBool:lockEnabled forKey:@"applock-lock-enabled"];
}

- (NSInteger)lockDelay
{
	NSNumber *lockDelay = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeLockDelay];

	if (lockDelay == nil)
	{
		lockDelay = [_userDefaults objectForKey:@"applock-lock-delay"];
	}

	return (lockDelay.integerValue);
}

- (void)setLockDelay:(NSInteger)lockDelay
{
	[_userDefaults setInteger:lockDelay forKey:@"applock-lock-delay"];
}

- (BOOL)biometricalSecurityEnabled
{
	NSNumber *useBiometricalUnlockNumber;
	BOOL useBiometricalUnlock = NO;

	if ((useBiometricalUnlockNumber = [_userDefaults objectForKey:@"security-settings-use-biometrical"]) != nil)
	{
		useBiometricalUnlock = useBiometricalUnlockNumber.boolValue;
	}
	else
	{
		useBiometricalUnlock = [[self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeUseBiometricalUnlock] boolValue];
	}

	if (useBiometricalUnlock)
	{
		// Apple share extension specific settings
		if ([OCAppIdentity.sharedAppIdentity.componentIdentifier isEqual:OCAppComponentIdentifierShareExtension])
		{
			return ([self biometricalSecurityEnabledinShareSheet]);
		}
	}

	return (useBiometricalUnlock);
}

- (void)setBiometricalSecurityEnabled:(BOOL)biometricalSecurityEnabled
{
	[_userDefaults setBool:biometricalSecurityEnabled forKey:@"security-settings-use-biometrical"];
}

- (NSDictionary<NSString*,id> *)_shareSheetBiometricalAttributesForApp:(NSString *)hostAppID
{
	NSDictionary<NSString*,NSDictionary *> *shareSheetBiometricalUnlockByApp = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeShareSheetBiometricalUnlockByApp];
	NSDictionary<NSString*,id> *attributesForApp = nil;

	if ([shareSheetBiometricalUnlockByApp isKindOfClass:NSDictionary.class])
	{
		if (shareSheetBiometricalUnlockByApp[hostAppID] != nil)
		{
			attributesForApp = OCTypedCast(shareSheetBiometricalUnlockByApp[hostAppID], NSDictionary);
		}
		else
		{
			attributesForApp = OCTypedCast(shareSheetBiometricalUnlockByApp[@"default"], NSDictionary);
		}
	}

	return (attributesForApp);
}

- (NSDictionary<NSString*,id> *)_shareSheetBiometricalAttributes
{
	NSString *hostAppID;

	if ((hostAppID = OCAppIdentity.sharedAppIdentity.hostAppBundleIdentifier) == nil)
	{
		hostAppID = @"default";
	}

	return ([self _shareSheetBiometricalAttributesForApp:hostAppID]);
}

- (BOOL)biometricalSecurityEnabledinShareSheet
{
	NSNumber *useBiometricalUnlock;

	if ((useBiometricalUnlock = [_userDefaults objectForKey:@"security-settings-use-biometrical-share-sheet"]) != nil)
	{
		return (useBiometricalUnlock.boolValue);
	}

	NSDictionary<NSString*,id> *shareSheetAttributesForApp = nil;

	if ((shareSheetAttributesForApp = [self _shareSheetBiometricalAttributes]) != nil)
	{
		NSNumber *enabled;

		if ((enabled = OCTypedCast(shareSheetAttributesForApp[@"allow"], NSNumber)) != nil)
		{
			return (enabled.boolValue);
		}
	}

	return (YES);
}

- (void)setBiometricalSecurityEnabledinShareSheet:(BOOL)biometricalSecurityEnabledinShareSheet
{
	[_userDefaults setBool:biometricalSecurityEnabledinShareSheet forKey:@"security-settings-use-biometrical-share-sheet"];
}

- (NSURL *)biometricalAuthenticationRedirectionTargetURL
{
	if ([OCAppIdentity.sharedAppIdentity.componentIdentifier isEqual:OCAppComponentIdentifierShareExtension])
	{
		// Only in share extension
		NSDictionary<NSString*,id> *shareSheetAttributesForApp = nil;

		if ((shareSheetAttributesForApp = [self _shareSheetBiometricalAttributes]) != nil)
		{
			NSString *trampolineURLString;

			// For apps with a trampoline URL, determine the target URL to initiate the authentication trampoline
			if ((trampolineURLString = shareSheetAttributesForApp[@"trampoline-url"]) != nil)
			{
				NSString *toAppURLScheme;

				if ((toAppURLScheme = [Branding.sharedBranding appURLSchemesForBundleURLName:nil].firstObject) != nil)
				{
					NSString *targetURLString = [NSString stringWithFormat:@"%@://?authenticateForApp=%@", toAppURLScheme, OCAppIdentity.sharedAppIdentity.hostAppBundleIdentifier];

					return ([NSURL URLWithString:targetURLString]);
				}
			}
		}
	}

	return (nil);
}

// Counterpart to .biometricalAuthenticationRedirectionTargetURL for use in the app (not implemented)
//- (NSURL *)biometricalAuthenticationReturnURL
//{
//	return (nil);
//}

- (BOOL)isPasscodeEnforced
{
	NSNumber *isPasscodeEnforced = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeEnforced];
	NSNumber *isPasscodeEnforcedByDevice = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeEnforcedByDevice];
	
	LAContext *context = [[LAContext alloc] init];
	NSError *error = nil;
	
	if (isPasscodeEnforcedByDevice != nil && isPasscodeEnforcedByDevice.boolValue == YES && [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error] == NO) {
		return (YES);
	} else if (isPasscodeEnforced != nil) {
		return (isPasscodeEnforced.boolValue);
	}

	return (NO);
}

- (NSInteger)requiredPasscodeDigits
{
	NSNumber *requiredPasscodeDigits = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyRequiredPasscodeDigits];

	if ((requiredPasscodeDigits != nil) && (requiredPasscodeDigits.integerValue > 4)) {
		return (requiredPasscodeDigits.integerValue);
	}

	return (4);
}

- (NSInteger)maximumPasscodeDigits
{
	NSNumber *maximumPasscodeDigits = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyMaximumPasscodeDigits];

	if (maximumPasscodeDigits != nil) {
		return (maximumPasscodeDigits.integerValue);
	}

	return (6);
}

- (BOOL)lockDelayUserSettable
{
	return ([self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeLockDelay] == nil);
}

@end

OCClassSettingsIdentifier OCClassSettingsIdentifierPasscode = @"passcode";

OCClassSettingsKey OCClassSettingsKeyPasscodeEnforced = @"enforced";
OCClassSettingsKey OCClassSettingsKeyPasscodeEnforcedByDevice = @"enforced-by-device";
OCClassSettingsKey OCClassSettingsKeyRequiredPasscodeDigits = @"requiredPasscodeDigits";
OCClassSettingsKey OCClassSettingsKeyMaximumPasscodeDigits = @"maximumPasscodeDigits";
OCClassSettingsKey OCClassSettingsKeyPasscodeLockDelay = @"lockDelay";
OCClassSettingsKey OCClassSettingsKeyPasscodeUseBiometricalUnlock = @"use-biometrical-unlock";
OCClassSettingsKey OCClassSettingsKeyPasscodeShareSheetBiometricalUnlockByApp = @"share-sheet-biometrical-unlock-by-app";
