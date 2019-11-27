//
//  OCLicenseOffer.m
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "OCLicenseOffer.h"
#import "OCLicenseProduct.h"

@implementation OCLicenseOffer

+ (instancetype)offerWithIdentifier:(OCLicenseOfferIdentifier)identifier type:(OCLicenseType)type product:(OCLicenseProductIdentifier)productIdentifier
{
	OCLicenseOffer *offer = [self new];

	offer.identifier = identifier;
	offer.type = type;
	offer.productIdentifier = productIdentifier;

	return (offer);
}

#pragma mark - Availability
- (BOOL)available
{
	if ((_fromDate!=nil) && ([_fromDate timeIntervalSinceNow] > 0))
	{
		return (NO);
	}

	if ((_untilDate!=nil) && ([_untilDate timeIntervalSinceNow] < 0))
	{
		return (NO);
	}

	return (_available);
}

#pragma mark - Price information
- (NSString *)localizedPriceTag
{
	if (_localizedPriceTag == nil)
	{
		if (_price == nil)
		{
			return (OCLocalized(@"Free"));
		}
		else
		{
			NSNumberFormatter *numberFormatter = [NSNumberFormatter new];

			numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
			numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;

			if (_priceLocale != nil)
			{
				numberFormatter.locale = _priceLocale;
			}

			_localizedPriceTag = [numberFormatter stringFromNumber:self.price];
		}
	}


	return (_localizedPriceTag);
}

#pragma mark - Request offer / Make purchase
- (void)commitWithOptions:(OCLicenseOfferCommitOptions)options
{
	
}

#pragma mark - Description
+ (NSString *)stringForOfferState:(OCLicenseOfferState)offerState
{
	switch (offerState)
	{
		case OCLicenseOfferStateUncommitted:
			return (@"uncommitted");
		break;

		case OCLicenseOfferStateRedundant:
			return (@"redundant");
		break;

		case OCLicenseOfferStateInProgress:
			return (@"in progress");
		break;

		case OCLicenseOfferStateCommitted:
			return (@"committed");
		break;
	}

	return (@"unknown");
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"<%@: %p, type: %@, identifier: %@, state: %@, productIdentifier: %@, localizedPriceTag: %@>", NSStringFromClass(self.class), self, [OCLicenseProduct stringForType:self.type], self.identifier, [OCLicenseOffer stringForOfferState:self.state], self.productIdentifier, self.localizedPriceTag]);
}

@end

OCLicenseOfferCommitOption OCLicenseOfferCommitOptionBaseViewController = @"BaseViewController";
