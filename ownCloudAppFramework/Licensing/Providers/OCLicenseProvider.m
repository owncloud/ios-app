//
//  OCLicenseProvider.m
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

#import "OCLicenseProvider.h"
#import "OCLicenseEntitlement.h"
#import "OCLicenseOffer.h"

@implementation OCLicenseProvider

- (instancetype)initWithIdentifier:(OCLicenseProviderIdentifier)identifier
{
	if ((self = [super init]) != nil)
	{
		_identifier = identifier;
	}

	return (self);
}

- (void)setEntitlements:(NSArray<OCLicenseEntitlement *> *)entitlements
{
	for (OCLicenseEntitlement *entitlement in _entitlements)
	{
		if ([entitlements indexOfObjectIdenticalTo:entitlement] == NSNotFound)
		{
			entitlement.provider = nil;
		}
	}

	for (OCLicenseEntitlement *entitlement in entitlements)
	{
		entitlement.provider = self;
	}

	_entitlements = entitlements;
}

- (void)setOffers:(NSArray<OCLicenseOffer *> *)offers
{
	for (OCLicenseOffer *offer in _offers)
	{
		if ([offers indexOfObjectIdenticalTo:offer] == NSNotFound)
		{
			offer.provider = nil;
		}
	}

	for (OCLicenseOffer *offer in offers)
	{
		offer.provider = self;
	}

	_offers = offers;
}

#pragma mark - Transaction access
- (void)retrieveTransactionsWithCompletionHandler:(void (^)(NSError * _Nullable, NSArray<OCLicenseTransaction *> * _Nullable))completionHandler
{
	completionHandler(nil, nil);
}

#pragma mark - Control
- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{

}

- (void)stopProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{

}

#pragma mark - Storage
- (NSData *)storedData
{
	if (self.storageURL != nil)
	{
		return ([NSData dataWithContentsOfURL:self.storageURL]);
	}

	return (nil);
}

- (void)setStoredData:(NSData *)storedData
{
	if (self.storageURL != nil)
	{
		if (storedData != nil)
		{
			[storedData writeToURL:self.storageURL atomically:YES];
		}
		else
		{
			[NSFileManager.defaultManager removeItemAtURL:self.storageURL error:NULL];
		}
	}
}

@end
