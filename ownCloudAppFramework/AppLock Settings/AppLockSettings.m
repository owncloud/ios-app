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
		OCClassSettingsKeyRequiredPasscodeDigits : @(4),
		OCClassSettingsKeyMaximumPasscodeDigits : @(6),
		OCClassSettingsKeyPasscodeUseBiometricalUnlock : @(NO)
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

		OCClassSettingsKeyPasscodeUseBiometricalUnlock : @{
			OCClassSettingsMetadataKeyType 		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription 	: @"Controls wether the biometrical unlock will be enabled automatically.",
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
	NSNumber *useBiometricalUnlock;

	if ((useBiometricalUnlock = [_userDefaults objectForKey:@"security-settings-use-biometrical"]) != nil)
	{
		return (useBiometricalUnlock.boolValue);
	}

	return ([[self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeUseBiometricalUnlock] boolValue]);
}

- (void)setBiometricalSecurityEnabled:(BOOL)biometricalSecurityEnabled
{
	[_userDefaults setBool:biometricalSecurityEnabled forKey:@"security-settings-use-biometrical"];
}

- (BOOL)isPasscodeEnforced
{
	NSNumber *isPasscodeEnforced = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyPasscodeEnforced];

	if (isPasscodeEnforced != nil) {
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
OCClassSettingsKey OCClassSettingsKeyRequiredPasscodeDigits = @"requiredPasscodeDigits";
OCClassSettingsKey OCClassSettingsKeyMaximumPasscodeDigits = @"maximumPasscodeDigits";
OCClassSettingsKey OCClassSettingsKeyPasscodeLockDelay = @"lockDelay";
OCClassSettingsKey OCClassSettingsKeyPasscodeUseBiometricalUnlock = @"use-biometrical-unlock";
