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

@interface OCLicenseEntitlement : NSObject

#pragma mark - Metadata
@property(nullable,strong) OCLicenseEntitlementIdentifier identifier; //!< (optional) identifier uniquely identifying this license entitlement
@property(weak) OCLicenseProvider *provider; //!< Provider from which this entitlement originated

#pragma mark - Product info
@property(strong) OCLicenseProductIdentifier productIdentifier; //!< Identifiers of the product targeted by this entitlement

#pragma mark - Payload
@property(assign) OCLicenseType type;
@property(nonatomic,assign) BOOL valid; //!< If the entitlement is currently valid
@property(nullable,strong) NSDate *expiryDate; //!< Date the entitlement expires - or nil if it doesn't expire

@end

NS_ASSUME_NONNULL_END
