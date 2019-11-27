//
//  OCLicenseFeature.h
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
@class OCLicenseProduct;
@class OCLicenseEntitlement;

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseFeature : NSObject

@property(nullable,weak) OCLicenseManager *manager;

#pragma mark - Metadata
@property(strong,readonly) OCLicenseFeatureIdentifier identifier; //!< Identifier uniquely identifying a feature

#pragma mark - Ownership
@property(strong) NSHashTable<OCLicenseProduct *> *containedInProducts; //!< Products in which this feature is contained
@property(nullable,strong,nonatomic) NSArray<OCLicenseEntitlement *> *entitlements; //!< Array of entitlements relevant to this feature

+ (instancetype)featureWithIdentifier:(OCLicenseFeatureIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END
