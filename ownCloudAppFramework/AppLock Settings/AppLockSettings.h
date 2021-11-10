//
//  AppLockSettings.h
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

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppLockSettings : NSObject <OCClassSettingsSupport>
{
	NSUserDefaults *_userDefaults;
}

@property(class,strong,nonatomic,readonly) AppLockSettings *sharedAppLockSettings;

@property(assign,nonatomic) BOOL lockEnabled;
@property(assign,nonatomic) NSInteger lockDelay;
@property(assign,nonatomic) BOOL biometricalSecurityEnabled;

@property(readonly,nonatomic) BOOL isPasscodeEnforced;
@property(readonly,nonatomic) NSInteger requiredPasscodeDigits;
@property(readonly,nonatomic) NSInteger maximumPasscodeDigits;
@property(readonly,nonatomic) BOOL lockDelayUserSettable;

@end

extern OCClassSettingsIdentifier OCClassSettingsIdentifierPasscode;

extern OCClassSettingsKey OCClassSettingsKeyPasscodeEnforced;
extern OCClassSettingsKey OCClassSettingsKeyRequiredPasscodeDigits;
extern OCClassSettingsKey OCClassSettingsKeyMaximumPasscodeDigits;
extern OCClassSettingsKey OCClassSettingsKeyPasscodeLockDelay;
extern OCClassSettingsKey OCClassSettingsKeyPasscodeUseBiometricalUnlock;

NS_ASSUME_NONNULL_END
