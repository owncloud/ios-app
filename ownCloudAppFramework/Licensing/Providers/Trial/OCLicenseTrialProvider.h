//
//  OCLicenseTrialProvider.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 22.11.19.
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

@interface OCLicenseTrialProvider : OCLicenseProvider

+ (instancetype)trialProviderWithIdentifier:(OCLicenseProviderIdentifier)identifier forProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)productIdentifiers withDuration:(NSTimeInterval)trialDuration;

@property(strong) NSArray<OCLicenseProductIdentifier> *productIdentifiers; //!< Array of product identifiers covered by this trial
@property(assign) NSTimeInterval trialDuration; //!< The duration of the trial(s) in seconds

@end

NS_ASSUME_NONNULL_END
