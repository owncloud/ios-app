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
#import "OCLicenseEntitlement.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseFeature : NSObject

#pragma mark - Metadata
@property(strong) OCLicenseFeatureIdentifier identifier; //!< Identifier uniquely identifying a feature
@property(nullable,strong) NSString *localizedName; //!< (optional) localized name of the feature

#pragma mark - Access information
@property(nullable,strong) NSArray<OCLicenseEntitlement *> *entitlements; //!< Array of entitlements relevant to this feature
@property(nonatomic,readonly) BOOL accessAllowed; //!< YES if access to this feature should be allowed

@end

NS_ASSUME_NONNULL_END
