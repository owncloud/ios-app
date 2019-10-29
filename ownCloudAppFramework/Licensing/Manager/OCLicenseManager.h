//
//  OCLicenseManager.h
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

NS_ASSUME_NONNULL_BEGIN

@class OCLicenseFeature;
@class OCLicenseProvider;
@class OCLicenseProduct;
@class OCLicenseObserver;

@interface OCLicenseManager : NSObject

@property(strong,nonatomic,class,readonly) OCLicenseManager *sharedLicenseManager;

#pragma mark - Feature/Product registration
- (void)registerFeature:(OCLicenseFeature *)feature;
- (void)registerProduct:(OCLicenseProduct *)product;

#pragma mark - Provider management
- (void)addProvider:(OCLicenseProvider *)provider;
- (void)removeProvider:(OCLicenseProvider *)provider;

#pragma mark - Observation
- (OCLicenseObserver *)observeProducts:(nullable NSArray<OCLicenseProductIdentifier> *)productIdentifiers features:(nullable NSArray<OCLicenseFeatureIdentifier *> *)featureIdentifiers inEnvironment:(OCLicenseEnvironment *)environment withOwner:(nullable id)owner updateHandler:(OCLicenseObserverUpdateHandler)updateHandler;
- (void)stopObserver:(OCLicenseObserver *)observer;

@end

NS_ASSUME_NONNULL_END
