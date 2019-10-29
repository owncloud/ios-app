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

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseProduct : NSObject

#pragma mark - Metadata
@property(strong) OCLicenseProductIdentifier identifier;
@property(strong) NSString *localizedName;

#pragma mark - Feature set
@property(strong) NSArray<OCLicenseFeatureIdentifier> *contents;

@end

NS_ASSUME_NONNULL_END
