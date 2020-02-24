//
//  OCLicenseEnterpriseProvider.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 05.12.19.
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

#import "OCLicenseProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseEnterpriseProvider : OCLicenseProvider

@property(strong,readonly) NSArray<OCLicenseProductIdentifier> *unlockedProductIdentifiers;

- (instancetype)initWithUnlockedProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)unlockedProductIdentifiers;

@end

extern OCLicenseProviderIdentifier OCLicenseProviderIdentifierEnterprise;

NS_ASSUME_NONNULL_END
