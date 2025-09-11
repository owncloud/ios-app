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

@property(class,strong,nonatomic,readonly) NSArray<OCExtensionIdentifier> *autoDisallowedActions; //!< List of identifiers of action extensions that would be automatically disallowed when enabling confidential protections and not making use of any exemptions.

@property (nonatomic, readonly) BOOL allowScreenshots;
@property (nonatomic, readonly) BOOL markConfidentialViews;
@property (nonatomic, readonly) BOOL allowOverwriteConfidentialMDMSettings;
@property (nonatomic, readonly) BOOL confidentialSettingsEnabled;

@property (nonatomic, readonly) CGFloat textOpacity;
@property (nonatomic, readonly, nullable) NSString *textColor;
@property (nonatomic, readonly) CGFloat columnSpacing;
@property (nonatomic, readonly) CGFloat lineSpacing;
@property (nonatomic, readonly) BOOL showUserEmail;
@property (nonatomic, readonly) BOOL showUserID;
@property (nonatomic, readonly) BOOL showTimestamp;
@property (nonatomic, readonly, nullable) NSString *customText;
@property (nonatomic, readonly) NSInteger visibleRedactedCharacters;
@property (nonatomic, readonly, nullable) NSArray<OCExtensionIdentifier> *exemptActions; //!< Identifiers of action extensions exempt from automatically being disallowed when enabling confidential protections.
@property (nonatomic, readonly, nullable) NSArray<OCExtensionIdentifier> *disallowedActions;

@end

extern OCClassSettingsSourceIdentifier OCClassSettingsSourceIdentifierConfidentialManager;

extern OCClassSettingsIdentifier OCClassSettingsIdentifierConfidential;

extern OCClassSettingsKey OCClassSettingsKeyAllowScreenshots;
extern OCClassSettingsKey OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialExemptedActions;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextOpacity;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextColor;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextColumnSpacing;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextLineSpacing;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialVisibleRedactedCharacters;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowUserEmail;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowUserID;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowTimestamp;
extern OCClassSettingsKey OCClassSettingsKeyConfidentialTextCustomText;

NS_ASSUME_NONNULL_END
