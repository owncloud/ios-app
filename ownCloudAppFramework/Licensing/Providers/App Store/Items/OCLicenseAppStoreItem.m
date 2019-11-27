//
//  OCLicenseAppStoreItem.m
//  ownCloud
//
//  Created by Felix Schwarz on 25.11.19.
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

#import "OCLicenseAppStoreItem.h"

@implementation OCLicenseAppStoreItem

+ (instancetype)trialWithAppStoreIdentifier:(OCLicenseAppStoreItemIdentifier)identifier trialDuration:(NSTimeInterval)trialDuration productIdentifier:(OCLicenseProductIdentifier)productIdentifier
{
	return ([[self alloc] initWithType:OCLicenseTypeTrial identifier:identifier productIdentifier:productIdentifier trialDuration:trialDuration]);
}

+ (instancetype)nonConsumableIAPWithAppStoreIdentifier:(OCLicenseAppStoreItemIdentifier)identifier productIdentifier:(OCLicenseProductIdentifier)productIdentifier;
{
	return ([[self alloc] initWithType:OCLicenseTypePurchase identifier:identifier productIdentifier:productIdentifier trialDuration:0]);
}

+ (instancetype)subscriptionWithAppStoreIdentifier:(OCLicenseAppStoreItemIdentifier)identifier productIdentifier:(OCLicenseProductIdentifier)productIdentifier;
{
	return ([[self alloc] initWithType:OCLicenseTypeSubscription identifier:identifier productIdentifier:productIdentifier trialDuration:0]);
}

- (instancetype)initWithType:(OCLicenseType)type identifier:(OCLicenseAppStoreItemIdentifier)identifier productIdentifier:(OCLicenseProductIdentifier)productIdentifier trialDuration:(NSTimeInterval)trialDuration
{
	if ((self = [self init]) != nil)
	{
		_type = type;
		_identifier = identifier;
		_productIdentifier = productIdentifier;
		_trialDuration = trialDuration;
	}

	return (self);
}

@end
