//
//  OCLicenseProduct.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 29.10.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <Foundation/Foundation.h>
#import "OCLicenseTypes.h"

@class OCLicenseManager;
@class OCLicenseEntitlement;
@class OCLicenseFeature;

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseProduct : NSObject

@property(weak,nullable) OCLicenseManager *manager;

#pragma mark - Metadata
@property(strong,readonly) OCLicenseProductIdentifier identifier; //!< Identifier uniquely identifying the product

@property(strong) NSString *localizedName; //!< Localized name of the product
@property(nullable,strong) NSString *localizedDescription; //!< Localized description of the product

#pragma mark - Feature set
@property(nullable,strong,readonly) NSArray<OCLicenseFeatureIdentifier> *contents; //!< Array of feature identifiers of features contained in this product
@property(nullable,strong,nonatomic) NSArray<OCLicenseFeature *> *features; //!< Array of features contained in this product

#pragma mark - Access information
@property(nullable,strong,nonatomic) NSArray<OCLicenseEntitlement *> *entitlements; //!< Array of entitlements relevant to this product

+ (instancetype)productWithIdentifier:(OCLicenseProductIdentifier)identifier name:(NSString *)localizedName description:(nullable NSString *)localizedDescription contents:(NSArray<OCLicenseFeatureIdentifier> *)contents;

#pragma mark - Tools
+ (NSString *)stringForType:(OCLicenseType)type;

@end

NS_ASSUME_NONNULL_END
