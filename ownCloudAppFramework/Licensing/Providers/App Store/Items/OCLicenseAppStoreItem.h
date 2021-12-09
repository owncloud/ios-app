//
//  OCLicenseAppStoreItem.h
//  ownCloud
//
//  Created by Felix Schwarz on 25.11.19.
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
#import <StoreKit/StoreKit.h>
#import "OCLicenseOffer.h"
#import "OCLicenseDuration.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString* OCLicenseAppStoreProductIdentifier;

@interface OCLicenseAppStoreItem : NSObject

@property(strong,readonly) OCLicenseAppStoreProductIdentifier identifier;

@property(assign,readonly) OCLicenseType type;

@property(strong,readonly) OCLicenseDuration *trialDuration;

@property(strong,readonly) OCLicenseProductIdentifier productIdentifier;

@property(nullable,strong) SKProduct *storeProduct;
@property(nullable,strong) OCLicenseOffer *offer;

+ (instancetype)trialWithAppStoreIdentifier:(OCLicenseAppStoreProductIdentifier)identifier trialDuration:(OCLicenseDuration *)trialDuration productIdentifier:(OCLicenseProductIdentifier)productIdentifier;

+ (instancetype)nonConsumableIAPWithAppStoreIdentifier:(OCLicenseAppStoreProductIdentifier)identifier productIdentifier:(OCLicenseProductIdentifier)productIdentifier;

+ (instancetype)subscriptionWithAppStoreIdentifier:(OCLicenseAppStoreProductIdentifier)identifier productIdentifier:(OCLicenseProductIdentifier)productIdentifier trialDuration:(OCLicenseDuration *)trialDuration;

@end

NS_ASSUME_NONNULL_END
