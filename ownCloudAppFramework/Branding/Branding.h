//
//  Branding.h
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

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString* BrandingLegacyKeyPath;
typedef NSString* BrandingLegacyKey;
typedef OCClassSettingsKey BrandingKey NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString* BrandingImageName NS_TYPED_EXTENSIBLE_ENUM;

@protocol BrandingInitialization <NSObject>
+ (void)initializeBranding;
- (void)initializeSharedBranding;
@end

@interface Branding : NSObject <OCClassSettingsSupport>

@property(strong,nonatomic,readonly,class) Branding *sharedBranding;
@property(assign,nonatomic) BOOL allowBranding; //!< YES if branding is allowed. If NO, computedValueForClassSettingsKey returns only default values.

@property(strong,nullable,nonatomic,readonly) NSBundle *appBundle; //!< Bundle of the main app

@property(strong) NSDictionary<OCClassSettingsKey, BrandingLegacyKeyPath> *legacyKeyPathsByClassSettingsKeys;
- (void)registerLegacyKeyPath:(BrandingLegacyKeyPath)keyPath forClassSettingsKey:(OCClassSettingsKey)classSettingsKey;

@property(strong,nullable,nonatomic,readonly) NSDictionary<BrandingLegacyKey, id> *brandingProperties;
@property(assign,nonatomic,readonly) BOOL brandingPropertiesFromLocalFile;

@property(strong,nullable,nonatomic,readonly) NSString *appName; //!< Custom app name
@property(strong,nullable,nonatomic,readonly) NSString *organizationName; //!< Custom organization name

- (nullable UIImage *)brandedImageNamed:(BrandingImageName)imageName; //!< Returns the respective image from the appBundle

- (nullable id)computedValueForClassSettingsKey:(OCClassSettingsKey)classSettingsKey;
- (nullable NSURL *)urlForClassSettingsKey:(OCClassSettingsKey)settingsKey;

@end

extern OCClassSettingsIdentifier OCClassSettingsIdentifierBranding;

extern BrandingKey BrandingKeyAppName;
extern BrandingKey BrandingKeyOrganizationName;

NS_ASSUME_NONNULL_END


