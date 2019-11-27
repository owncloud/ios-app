//
//  OCLicenseAppStoreProvider.m
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

#import <StoreKit/StoreKit.h>

#import "OCLicenseAppStoreProvider.h"

@interface OCLicenseAppStoreProvider () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
	OCLicenseProviderCompletionHandler _startCompletionHandler;
}

@property(nullable,strong) SKProductsRequest *request;
@property(nullable,strong) SKProductsResponse *response;

@end

@implementation OCLicenseAppStoreProvider

- (instancetype)initWithItems:(NSArray<OCLicenseAppStoreItem *> *)items
{
	if ((self = [super init]) != nil)
	{
		_items = items;
	}

	return (self);
}

#pragma mark - Mapping
- (nullable OCLicenseProductIdentifier)productIdentifierForAppStoreIdentifier:(OCLicenseAppStoreItemIdentifier)identifier
{
	for (OCLicenseAppStoreItem *item in _items)
	{
		if ([item.identifier isEqual:identifier])
		{
			return (item.productIdentifier);
		}
	}

	return (nil);
}

#pragma mark - Start providing
- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	if (_request == nil)
	{
		NSMutableSet<OCLicenseAppStoreItemIdentifier> *appStoreIdentifiers = [NSMutableSet new];

		// Build product request
		for (OCLicenseAppStoreItem *item in _items)
		{
			[appStoreIdentifiers addObject:item.identifier];
		}

		_startCompletionHandler = [completionHandler copy];

		_request = [[SKProductsRequest alloc] initWithProductIdentifiers:appStoreIdentifiers];
		_request.delegate = self;

		[_request start];

		// Add the provider as transaction observer
		[SKPaymentQueue.defaultQueue addTransactionObserver:self]; // needs to be called in -[UIApplicationDelegate application:didFinishLaunchingWithOptions:] to not miss a transaction
	}
}

- (void)stopProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	// Cancel product request if still ongoing
	if (_request != nil)
	{
		[_request cancel];
		_request = nil;
	}

	// Remove provider as transaction observer
	[SKPaymentQueue.defaultQueue removeTransactionObserver:self];
}

#pragma mark - Product request delegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	// Called on success
	self.response = response;

	// Parse response
	for (SKProduct *product in response.products)
	{
		for (OCLicenseAppStoreItem *item in _items)
		{
			if ([item.identifier isEqual:product.productIdentifier])
			{
				item.storeProduct = product;
				break;
			}
		}
	}

	// Create offers from items
	NSMutableArray<OCLicenseOffer *> *offers = [NSMutableArray new];

	for (OCLicenseAppStoreItem *item in _items)
	{
		SKProduct *storeProduct = nil;

		if ((storeProduct = item.storeProduct) != nil)
		{
			OCLicenseOffer *offer = nil;

			offer = [OCLicenseOffer offerWithIdentifier:[@"appstore." stringByAppendingString:storeProduct.productIdentifier] type:item.type product:item.productIdentifier];

			switch (item.type)
			{
				case OCLicenseTypePurchase:
				case OCLicenseTypeSubscription:
					offer.price = storeProduct.price;
					offer.priceLocale = storeProduct.priceLocale;
				break;

				case OCLicenseTypeTrial:
				break;

				default:
				break;
			}

			if (offer != nil)
			{
				[offers addObject:offer];
			}
		}
	}

	self.offers = (offers.count > 0) ? offers : nil;
}

- (void)requestDidFinish:(SKRequest *)request
{
	// Called last on success (not called on error)

	if (_startCompletionHandler != nil)
	{
		_startCompletionHandler(self, nil);
		_startCompletionHandler = nil;
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	// Called last on error
	if (_startCompletionHandler != nil)
	{
		_startCompletionHandler(self, error);
		_startCompletionHandler = nil;
	}
}

#pragma mark - Payment transaction observation
// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	
}

@end
