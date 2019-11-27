//
//  OCLicenseAppStoreProvider.h
//  ownCloud
//
//  Created by Felix Schwarz on 24.11.19.
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
#import "OCLicenseAppStoreItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseAppStoreProvider : OCLicenseProvider

@property(strong) NSArray<OCLicenseAppStoreItem *> *items;

- (instancetype)initWithItems:(NSArray<OCLicenseAppStoreItem *> *)items;

@end

NS_ASSUME_NONNULL_END
