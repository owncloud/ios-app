//
//  OCLicenseProvider.h
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

@class OCLicenseOffer;
@class OCLicenseEntitlement;

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseProvider : NSObject

#pragma mark - Metadata
@property(strong) OCLicenseProviderIdentifier identifier; //!< Identifier uniquely identifying this license provider
@property(nullable,strong) NSString *localizedName; //!< (optional) localized name of the license provider

#pragma mark - Payload
@property(nullable,strong) NSArray <OCLicenseOffer *> *offers; //!< Offers made available by the provider. Updates to this property trigger updates in OCLicenseManager.
@property(nullable,strong) NSArray <OCLicenseEntitlement *> *entitlements; //!< Entitlements found by the provider. Updates to this property trigger updates in OCLicenseManager.

@end

NS_ASSUME_NONNULL_END
