//
//  ConfidentialManager.h
//  ownCloud
//
//  Created by Matthias Hühne on 09.12.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
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

@interface ConfidentialManager : NSObject <OCClassSettingsSupport, OCClassSettingsSource>

@property(class,strong,nonatomic,readonly) ConfidentialManager *sharedConfidentialManager;

@property (assign, readonly) BOOL allowScreenshots;
@property (assign, readonly) BOOL markConfidentialViews;
@property (assign, readonly) BOOL allowOverwriteConfidentialMDMSettings;
@property (assign, readonly) BOOL confidentialSettingsEnabled;
@property (nonatomic, readonly, nullable) NSArray<OCExtensionIdentifier> *disallowedActions;

@end

extern OCClassSettingsSourceIdentifier OCClassSettingsSourceIdentifierConfidentialManager;

extern OCClassSettingsIdentifier OCClassSettingsIdentifierConfidential;

extern OCClassSettingsKey OCClassSettingsKeyAllowScreenshots;
extern OCClassSettingsKey OCClassSettingsKeyMarkConfidentialViews;
extern OCClassSettingsKey OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings;

NS_ASSUME_NONNULL_END
