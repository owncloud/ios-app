//
//  OCLicenseEntitlement.h
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

@class OCLicenseProvider;
@class OCLicenseEnvironment;

@interface OCLicenseEntitlement : NSObject

+ (instancetype)entitlementWithIdentifier:(nullable OCLicenseEntitlementIdentifier)identifier forProduct:(OCLicenseProductIdentifier)productIdentifier type:(OCLicenseType)type valid:(BOOL)valid expiryDate:(nullable NSDate *)expiryDate applicability:(nullable OCLicenseEntitlementEnvironmentApplicableRule)applicability;

#pragma mark - Metadata
@property(nullable,strong) OCLicenseEntitlementIdentifier identifier; //!< (optional) identifier uniquely identifying this license entitlement
@property(weak) OCLicenseProvider *provider; //!< Provider from which this entitlement originated

#pragma mark - Product info
@property(strong) OCLicenseProductIdentifier productIdentifier; //!< Identifiers of the product targeted by this entitlement

#pragma mark - Payload
@property(assign) OCLicenseType type;

@property(nonatomic,assign) BOOL valid; //!< If the entitlement is currently valid (i.e. has not expired)
@property(nullable,strong) NSDate *expiryDate; //!< Date the entitlement expires - or nil if it doesn't expire

@property(nullable,strong,nonatomic) NSDate *nextStatusChangeDate; //!< Date the entitlement should next be checked for changes - or nil if it doesn't need to be checked

@property(nullable,strong) OCLicenseEntitlementEnvironmentApplicableRule environmentApplicableRule; //!< If provided, a rule (as string) in NSPredicate notation to check an OCLicenseEnvironment for applicability. If nil, the entitlement's applicability is not dependent on the environment.
- (BOOL)isApplicableInEnvironment:(OCLicenseEnvironment *)environment; //!< Returns YES if the entitlement is applicable in the provided environment

- (OCLicenseAuthorizationStatus)authorizationStatusInEnvironment:(OCLicenseEnvironment *)environment; //!< Computes and returns the current authorization status for the respective environment based on .valid, .expiryDate and -isApplicableInEnvironment:

@end

NS_ASSUME_NONNULL_END
