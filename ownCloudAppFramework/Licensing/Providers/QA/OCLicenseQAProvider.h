//
//  OCLicenseQAProvider.h
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.01.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCLicenseProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OCLicenseQAProviderDelegate <NSObject>
@property(readonly) BOOL isQALicenseUnlockPossible;
@end

@interface OCLicenseQAProvider : OCLicenseProvider

@property(class,strong,readonly,nonatomic) OCLicenseQAProvider *sharedProvider; //!< Set to the first instantiated instance

@property(class,nonatomic) BOOL isQAUnlockEnabled;
@property(class,readonly,nonatomic) BOOL isQAUnlockPossible;

@property(strong,readonly) NSArray<OCLicenseProductIdentifier> *unlockedProductIdentifiers;

- (instancetype)initWithUnlockedProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)unlockedProductIdentifiers delegate:(id<OCLicenseQAProviderDelegate>)delegate;

- (void)updateEntitlements;

@end

extern OCLicenseProviderIdentifier OCLicenseProviderIdentifierQA;

NS_ASSUME_NONNULL_END
