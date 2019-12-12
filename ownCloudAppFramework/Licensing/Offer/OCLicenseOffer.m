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
#import "OCLicenseProvider.h"
#import "OCLicenseManager.h"

@implementation OCLicenseOffer

+ (instancetype)offerWithIdentifier:(OCLicenseOfferIdentifier)identifier type:(OCLicenseType)type product:(OCLicenseProductIdentifier)productIdentifier
{
	OCLicenseOffer *offer = [self new];

	offer.identifier = identifier;
	offer.type = type;
	offer.productIdentifier = productIdentifier;

	return (offer);
}

#pragma mark - Product info
- (OCLicenseProduct *)product
{
	return ([self.provider.manager productWithIdentifier:self.productIdentifier]);
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

- (OCLicenseOfferState)stateInEnvironment:(OCLicenseEnvironment *)environment
{
	if (!self.available)
	{
		// Offer is not currently available
		return (OCLicenseOfferStateUnavailable);
	}

	if (_state == OCLicenseOfferStateUncommitted)
	{
		if ([self.provider.manager authorizationStatusForProduct:_productIdentifier inEnvironment:environment] == OCLicenseAuthorizationStatusGranted)
		{
			// Contents of offer already paid for
			return (OCLicenseOfferStateRedundant);
		}
	}

	OCLicenseProduct *product;

	if ((product = [self.provider.manager productWithIdentifier:_productIdentifier]) != nil)
	{
		BOOL allFeaturesUnlocked = (product.contents.count > 0);

		for (OCLicenseFeatureIdentifier featureIdentifier in product.contents)
		{
			if ([self.provider.manager authorizationStatusForFeature:featureIdentifier inEnvironment:environment] != OCLicenseAuthorizationStatusGranted)
			{
				allFeaturesUnlocked = NO;
				break;
			}
		}

		if (allFeaturesUnlocked)
		{
			// Contents of product unlocked by offer already paid for
			return (OCLicenseOfferStateRedundant);
		}
	}

	if (_state == OCLicenseOfferStateCommitted)
	{
		if ([self.provider.manager authorizationStatusForProduct:_productIdentifier inEnvironment:environment] == OCLicenseAuthorizationStatusExpired)
		{
			// Offer was taken, but entitlements granted through it have since expired
			return (OCLicenseOfferStateExpired);
		}
	}

	return (_state);
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
	if (_commitHandler != nil)
	{
		_commitHandler(self, options);
	}
}

#pragma mark - Description
+ (NSString *)stringForOfferState:(OCLicenseOfferState)offerState
{
	switch (offerState)
	{
		case OCLicenseOfferStateUncommitted:
			return (@"uncommitted");
		break;

		case OCLicenseOfferStateUnavailable:
			return (@"unavailable");
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

		case OCLicenseOfferStateExpired:
			return (@"expired");
		break;
	}

	return (@"unknown");
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"<%@: %p, type: %@, identifier: %@, state: %@, available: %d, productIdentifier: %@, localizedPriceTag: %@%@%@%@%@%@%@>", NSStringFromClass(self.class), self, [OCLicenseProduct stringForType:self.type], self.identifier, [OCLicenseOffer stringForOfferState:self.state], self.available, self.productIdentifier, self.localizedPriceTag,
		((_fromDate != nil) ? [@", fromDate: " stringByAppendingString:_fromDate.description] : @""),
		((_untilDate != nil) ? [@", untilDate: " stringByAppendingString:_untilDate.description] : @""),
		((_trialDuration != nil) ? [@", trialDuration: " stringByAppendingString:_trialDuration.localizedDescription] : @""),
		((_subscriptionTermDuration != nil) ? [@", subscriptionTermDuration: " stringByAppendingString:_subscriptionTermDuration.localizedDescription] : @""),
		((_localizedTitle != nil) ? [@", localizedTitle: " stringByAppendingString:_localizedTitle] : @""),
		((_localizedDescription != nil) ? [@", localizedDescription: " stringByAppendingString:_localizedDescription] : @"")
	]);
}

@end

OCLicenseOfferCommitOption OCLicenseOfferCommitOptionBaseViewController = @"BaseViewController";
