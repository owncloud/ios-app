//
//  OCLicenseManager+Internal.h
//  ownCloud
//
//  Created by Felix Schwarz on 11.11.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

#import "OCLicenseManager.h"
#import "OCLicenseEntitlement.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseManager (Internal)

- (nullable NSArray <OCLicenseEntitlement *> *)_entitlementsForProduct:(OCLicenseProduct *)product; //!< Returns the entitlements covering the product

@end

NS_ASSUME_NONNULL_END
