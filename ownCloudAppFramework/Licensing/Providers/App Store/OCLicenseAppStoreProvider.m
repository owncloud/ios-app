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
#import <ownCloudSDK/ownCloudSDK.h>

#import "OCLicenseAppStoreProvider.h"
#import "OCLicenseManager.h"
#import "OCLicenseAppStoreReceipt.h"
#import "OCLicenseEntitlement.h"
#import "OCLicenseProduct.h"
#import "OCLicenseTransaction.h"
#import "OCLicenseOffer.h"

#define AppStoreOfferIdentifier(appStoreProductIdentifier) [@"appstore." stringByAppendingString:appStoreProductIdentifier]

OCIPCNotificationName OCIPCNotificationNameLicenseAppStoreProviderDataChanged = @"org.owncloud.app-store-provider.data-changed";

@interface OCLicenseAppStoreProvider () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
	OCLicenseAppStoreRefreshProductsCompletionHandler _productsRefreshCompletionHandler;
	BOOL _setupTransactionObserver;

	NSMutableDictionary<OCLicenseAppStoreProductIdentifier, NSNumber *> *_offerStateByAppStoreProductIdentifier;

	NSMutableDictionary<NSString *, OCLicenseOfferCommitErrorHandler> *_commitErrorHandlerByProductIdentifier;

	OCLicenseAppStoreRestorePurchasesCompletionHandler _restorePurchasesCompletionHandler;
	BOOL _appStoreReceiptNeedsReload;
}

@property(nullable,strong) SKProductsRequest *request;
@property(nullable,strong) SKProductsResponse *response;

@end

@implementation OCLicenseAppStoreProvider

#pragma mark - Init
- (instancetype)initWithItems:(NSArray<OCLicenseAppStoreItem *> *)items
{
	if ((self = [super initWithIdentifier:OCLicenseProviderIdentifierAppStore]) != nil)
	{
		OCTLogDebug(@[@"Init"], @"Initializing App Store Provider with items %@", items);

		_items = items;
		_offerStateByAppStoreProductIdentifier = [NSMutableDictionary new];

		_commitErrorHandlerByProductIdentifier = [NSMutableDictionary new];

		self.localizedName = OCLocalized(@"App Store");

		__weak OCLicenseAppStoreProvider *weakSelf = self;

		[OCIPNotificationCenter.sharedNotificationCenter addObserver:self forName:OCIPCNotificationNameLicenseAppStoreProviderDataChanged withHandler:^(OCIPNotificationCenter * _Nonnull notificationCenter, id  _Nonnull observer, OCIPCNotificationName  _Nonnull notificationName) {
			OCLogDebug(@"Received AppStoreProviderDataChanged notification");
			[weakSelf loadReceipt];
		}];
	}

	return (self);
}

- (void)dealloc
{
	[OCIPNotificationCenter.sharedNotificationCenter removeObserver:self forName:OCIPCNotificationNameLicenseAppStoreProviderDataChanged];
}

#pragma mark - Purchases allowed
- (BOOL)purchasesAllowed
{
	BOOL purchasesAllowed = SKPaymentQueue.canMakePayments;

	OCLogDebug(@"purchasesAllowed=%d", purchasesAllowed);

	return (purchasesAllowed);
}

- (BOOL)isVolumePurchase
{
	if ((_receipt != nil) && (_receipt.originalAppVersion != nil) && [_receipt.originalAppVersion isEqual:@""])
	{
		// For apps purchased / installed through the Volume Purchase Program (VPP), the field originalAppVersion
		// exists in the receipt, but contains just an empty string. Likely background (read: best-effort _assumption_
		// based on searching developer forums and own observations) is that originally purchased app versions are
		// stored as part of the respective App Store account, but for VPP none appears to be linked, so that info
		// can't be provided.
		return (YES);
	}

	return (NO);
}

#pragma mark - Mapping
- (nullable OCLicenseProductIdentifier)productIdentifierForAppStoreIdentifier:(OCLicenseAppStoreProductIdentifier)identifier
{
	return ([self itemForAppStoreIdentifier:identifier].productIdentifier);
}

- (nullable OCLicenseAppStoreItem *)itemForAppStoreIdentifier:(OCLicenseAppStoreProductIdentifier)identifier
{
	if (identifier == nil)
	{
		return (nil);
	}

	for (OCLicenseAppStoreItem *item in _items)
	{
		if ([item.identifier isEqual:identifier])
		{
			return (item);
		}
	}

	return (nil);
}

#pragma mark - Transaction access
- (void)retrieveTransactionsWithCompletionHandler:(void (^)(NSError * _Nullable, NSArray<OCLicenseTransaction *> * _Nullable))completionHandler
{
	OCTLogDebug(@[@"RetrieveTransactions"], @"Started retrieval..");

	if (self.receipt == nil)
	{
		OCTLogDebug(@[@"RetrieveTransactions"], @"No receipt found - restoring purchases");
		[self restorePurchasesWithCompletionHandler:^(NSError * _Nullable error) {
			OCTLogDebug(@[@"RetrieveTransactions"], @"Restore completed with error=%@, receipt=%@", error, self.receipt);
			completionHandler(error, [self _transactionsFromReceipt:self.receipt]);
		}];
	}
	else
	{
		OCTLogDebug(@[@"RetrieveTransactions"], @"Completed with existing receipt=%@", self.receipt);
		completionHandler(nil, [self _transactionsFromReceipt:self.receipt]);
	}
}

- (NSArray<OCLicenseTransaction *> *)_transactionsFromReceipt:(OCLicenseAppStoreReceipt *)receipt
{
	NSMutableArray <OCLicenseTransaction *> *transactions = nil;

	if (receipt != nil)
	{
		transactions = [NSMutableArray new];

		if (receipt.originalAppVersion != nil)
		{
			[transactions addObject:[OCLicenseTransaction transactionWithProvider:self tableRows:@[
				@{ OCLocalized(@"Purchased App Version") : receipt.originalAppVersion },
				@{ OCLocalized(@"Receipt Date") : (receipt.creationDate != nil) ? receipt.creationDate : @"-" }
			]]];
		}

		for (OCLicenseAppStoreReceiptInAppPurchase *iap in receipt.inAppPurchases)
		{
			OCLicenseProductIdentifier productID = [self productIdentifierForAppStoreIdentifier:iap.productID];
			OCLicenseProduct *product = [self.manager productWithIdentifier:productID];
			OCLicenseAppStoreItem *item = [self itemForAppStoreIdentifier:iap.productID];

			OCLicenseTransaction *transaction;

			transaction = [OCLicenseTransaction transactionWithProvider:self
										   identifier:iap.webOrderLineItemID.stringValue
											 type:item.type
										     quantity:iap.quantity.integerValue
											 name:((item.storeProduct.localizedTitle != nil) ? item.storeProduct.localizedTitle : ((product != nil) ? product.localizedName : iap.productID))
									    productIdentifier:product.identifier
											 date:iap.purchaseDate
										      endDate:iap.subscriptionExpirationDate
									     cancellationDate:iap.cancellationDate];
			if ((transaction.type == OCLicenseTypeSubscription) && (iap.subscriptionExpirationDate.timeIntervalSinceNow > 0) && ((iap.cancellationDate==nil) || (iap.cancellationDate.timeIntervalSinceNow > 0)))
			{
				transaction.links = @{ OCLocalized(@"Manage subscription") : [NSURL URLWithString:@"https://apps.apple.com/account/subscriptions"] };
			}

			[transactions addObject:transaction];
		}
	}

	return (transactions);
}

#pragma mark - Start providing
- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	OCTLogDebug(@[@"Start"], @"Start providing");

	if (!SKPaymentQueue.canMakePayments)
	{
		OCTLogWarning(@[@"Start"], @"SKPaymentQueue: can't make payments");
		completionHandler(self, nil);
		return;
	}

	__weak OCLicenseAppStoreProvider *weakSelf = self;

	OCTLogDebug(@[@"Start"], @"Initiating products refresh");

	// Transaction observation
	if (!_setupTransactionObserver)
	{
		// Did setup
		_setupTransactionObserver = YES;

		// Add the provider as transaction observer
		OCTLogDebug(@[@"Start"], @"Adding SKPaymentQueue transaction observer");
		[SKPaymentQueue.defaultQueue addTransactionObserver:self]; // needs to be called in -[UIApplicationDelegate application:didFinishLaunchingWithOptions:] to not miss a transaction

		// Add termination notification observer
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_processWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
	}

	// Refresh products
	[self refreshProductsWithCompletionHandler:^(NSError * _Nullable error) {
		OCTLogDebug(@[@"Start"], @"Products refresh completed with error=%@", error);
		completionHandler(weakSelf, error);
	}];

	// Load & refresh receipt as needed
	OCTLogDebug(@[@"Start"], @"Loading receipt");
	[self loadReceipt];

	OCTLogDebug(@[@"Start"], @"Reloading receipt if needed");
	[self reloadReceiptIfNeeded];
}

- (OCLicenseAppStoreReceipt *)receipt
{
	if (_receipt == nil)
	{
		[self loadReceipt];
	}

	return (_receipt);
}

- (void)_ipcNotifyToReloadReceipt
{
	[OCIPNotificationCenter.sharedNotificationCenter postNotificationForName:OCIPCNotificationNameLicenseAppStoreProviderDataChanged ignoreSelf:YES];
}

- (void)loadReceipt
{
	OCTLogDebug(@[@"LoadReceipt"], @"Loading App Store Receipt");

	OCLicenseAppStoreReceipt *receipt = OCLicenseAppStoreReceipt.defaultReceipt;
	OCLicenseAppStoreReceiptParseError parseError;

	if ((parseError = [receipt parse]) != OCLicenseAppStoreReceiptParseErrorNone)
	{
		OCTLogError(@[@"LoadReceipt"], @"Error %ld parsing App Store receipt.", (long)parseError);
	}

	[self willChangeValueForKey:@"receipt"];
	_receipt = receipt;
	[self didChangeValueForKey:@"receipt"];

	OCTLogDebug(@[@"LoadReceipt"], @"App Store Receipt loaded: %@", _receipt);

	[self recomputeEntitlements];
	[self recomputeOffers];
}

- (void)setReceiptNeedsReload
{
	OCTLogDebug(@[@"SetReceiptNeedsReload"], @"setReceiptNeedsReload was called");

	@synchronized(self)
	{
		_appStoreReceiptNeedsReload = YES;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[self reloadReceiptIfNeeded];
	});
}

- (void)reloadReceiptIfNeeded
{
	OCTLogDebug(@[@"ReloadReceiptIfNeeded"], @"reloadReceiptIfNeeded was called");

	OCLicenseAppStoreReceipt *receipt = self.receipt;
	BOOL needsReload = NO;

	if (receipt != nil)
	{
		if ((receipt.expirationDate != nil) && (receipt.expirationDate.timeIntervalSinceNow < 0))
		{
			// Receipt expired
			OCTLogDebug(@[@"ReloadReceiptIfNeeded"], @"Receipt expired as of %@ - reload needed", receipt.expirationDate);
			needsReload = YES;
		}
		else
		{
			for (OCLicenseAppStoreReceiptInAppPurchase *iap in receipt.inAppPurchases)
			{
				if ((iap.subscriptionExpirationDate != nil) && (iap.subscriptionExpirationDate.timeIntervalSinceNow < 0) && // IAP has expired
				   ([iap.subscriptionExpirationDate timeIntervalSinceDate:receipt.creationDate] > 0)) // The receipt was created before the IAP has expired
				{
					// Subscription expired
					OCTLogDebug(@[@"ReloadReceiptIfNeeded"], @"Subscription %@ expired as of %@ - reload needed", iap.productID, iap.subscriptionExpirationDate);
					needsReload = YES;
					break;
				}
			}
		}
	}

	BOOL reloadRequested = NO;

	@synchronized(self)
	{
		reloadRequested = _appStoreReceiptNeedsReload;
		_appStoreReceiptNeedsReload = NO;
	}

	if (needsReload || reloadRequested)
	{
		OCTLogDebug(@[@"ReloadReceiptIfNeeded"], @"App Store Receipt needsReload=%d and reloadRequested=%d", needsReload, reloadRequested);

		[self restorePurchasesWithCompletionHandler:^(NSError * _Nullable error) {
			OCTLogDebug(@[@"ReloadReceiptIfNeeded"], @"Restored purchases with error=%@", error);

			if (error != nil)
			{
				OCTLogError(@[@"ReloadReceiptIfNeeded"], @"Error restoring purchases: %@", error);
				return;
			}

			OCTLogDebug(@[@"ReloadReceiptIfNeeded"], @"Loading receipt");
			[self loadReceipt];
		}];
	}
}

- (void)_processWillTerminate
{
	// Remove the provider on app termination
	[self.manager removeProvider:self];
}

- (void)stopProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	OCTLogDebug(@[@"Stop"], @"Stopping provider");

	// Cancel product request if still ongoing
	if (_request != nil)
	{
		[_request cancel];
		_request = nil;
	}

	if (_setupTransactionObserver)
	{
		// Remove provider as transaction observer
		OCTLogDebug(@[@"Stop"], @"Removing transaction observer");
		[SKPaymentQueue.defaultQueue removeTransactionObserver:self];

		// Remove termination notification observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
	}
}

#pragma mark - Entitlements & Offers
- (void)recomputeEntitlements
{
	OCLicenseAppStoreReceipt *receipt = _receipt;
	NSMutableArray<OCLicenseEntitlement *> *entitlements = [NSMutableArray new];

	OCTLogDebug(@[@"Entitlements"], @"Recomputing entitlements…");

	for (OCLicenseAppStoreItem *item in self.items)
	{
		// Find corresponding IAPs
		NSMutableArray<OCLicenseAppStoreReceiptInAppPurchase *> *itemIAPs = nil;

		for (OCLicenseAppStoreReceiptInAppPurchase *iap in receipt.inAppPurchases)
		{
			if ([iap.productID isEqualToString:item.identifier])
			{
				if (itemIAPs == nil)
				{
					itemIAPs = [NSMutableArray new];
				}

				[itemIAPs addObject:iap];
			}
		}

		if (itemIAPs != nil)
		{
			// IAPs found => create entitlements
			OCLicenseEntitlement *entitlement;
			OCLicenseAppStoreReceiptInAppPurchase *iap = itemIAPs.lastObject; // If there's more than one IAP, assume the last to be the relevant one
			NSDate *expiryDate = nil;
			NSDate *purchaseDate = (iap.originalPurchaseDate != nil) ? iap.originalPurchaseDate : iap.purchaseDate;

			switch (item.type)
			{
				case OCLicenseTypeNone:
				break;

				case OCLicenseTypeTrial:
					expiryDate = [item.trialDuration dateWithDurationAddedTo:purchaseDate];
				break;

				case OCLicenseTypeSubscription:
					expiryDate = iap.subscriptionExpirationDate;
				break;

				case OCLicenseTypePurchase:
				break;
			}

			entitlement = [OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:item.productIdentifier type:item.type valid:YES expiryDate:expiryDate applicability:nil];

			[entitlements addObject:entitlement];
		}
	}

	self.entitlements = (entitlements.count > 0) ? entitlements : nil;
}

- (void)recomputeOffers
{
	// Create offers from items
	NSMutableArray<OCLicenseOffer *> *offers = [NSMutableArray new];

	OCTLogDebug(@[@"Offers"], @"Recomputing offers…");

	for (OCLicenseAppStoreItem *item in _items)
	{
		SKProduct *storeProduct = nil;

		if ((storeProduct = item.storeProduct) != nil)
		{
			OCLicenseOffer *offer = nil;
			OCLicenseAppStoreProductIdentifier appStoreProductIdentifier = storeProduct.productIdentifier;

			offer = [OCLicenseOffer offerWithIdentifier:AppStoreOfferIdentifier(appStoreProductIdentifier) type:item.type product:item.productIdentifier];

			offer.price = storeProduct.price;
			offer.priceLocale = storeProduct.priceLocale;

			offer.available = YES;

			offer.localizedTitle = storeProduct.localizedTitle;
			offer.localizedDescription = storeProduct.localizedDescription;

			NSMutableDictionary<NSString *, OCLicenseOfferCommitErrorHandler> *commitErrorHandlerByProductIdentifier = _commitErrorHandlerByProductIdentifier;

			offer.commitHandler = ^(OCLicenseOffer * _Nonnull offer, OCLicenseOfferCommitOptions  _Nullable options, OCLicenseOfferCommitErrorHandler _Nullable errorHandler) {
				OCLicenseAppStoreProvider *appStoreProvider = [offer.provider isKindOfClass:[OCLicenseAppStoreProvider class]] ? (OCLicenseAppStoreProvider *)offer.provider : nil;

				if (appStoreProvider != nil)
				{
					if (!appStoreProvider.purchasesAllowed || appStoreProvider.isVolumePurchase)
					{
						// Present alert
						if (errorHandler != nil)
						{
							errorHandler([NSError errorWithDomain:OCLicenseAppStoreProviderErrorDomain code:(appStoreProvider.isVolumePurchase ? OCLicenseAppStoreProviderErrorPurchasesNotAllowedForVPPCopies :  OCLicenseAppStoreProviderErrorPurchasesNotAllowed) userInfo:@{
								NSLocalizedDescriptionKey : (appStoreProvider.isVolumePurchase ?
									 OCLocalized(@"In-app purchases are not supported for copies purchased through the Volume Purchase Program. For access to additional features, please purchase the EMM version.") :
									 OCLocalized(@"Purchases are not allowed on this device."))
							}]);
						}
					}
					else
					{
						if ((errorHandler != nil) && (appStoreProductIdentifier!=nil))
						{
							commitErrorHandlerByProductIdentifier[appStoreProductIdentifier] = [errorHandler copy];
						}

						[appStoreProvider requestPaymentFor:storeProduct];
					}
				}
			};

			// Subscription and trial properties
			offer.trialDuration = item.trialDuration;

			if (storeProduct.subscriptionPeriod != nil)
			{
				offer.subscriptionTermDuration = storeProduct.subscriptionPeriod.licenseDuration;
			}

			offer.groupIdentifier = storeProduct.subscriptionGroupIdentifier;

			// Compute state
			[self _updateStateForOffer:offer withAppStoreProductIdentifier:appStoreProductIdentifier];

			// Add offer
			if (offer != nil)
			{
				[offers addObject:offer];
			}
		}
	}

	self.offers = (offers.count > 0) ? offers : nil;
}

- (void)_updateStateForOffer:(OCLicenseOffer *)offer withAppStoreProductIdentifier:(OCLicenseAppStoreProductIdentifier)appStoreProductIdentifier
{
	OCLicenseAppStoreReceipt *receipt = _receipt;

	// Derive state from payment queue
	if (_offerStateByAppStoreProductIdentifier[appStoreProductIdentifier] != nil)
	{
		offer.state = _offerStateByAppStoreProductIdentifier[appStoreProductIdentifier].unsignedIntegerValue;
	}

	// Derive state from receipt
	for (OCLicenseAppStoreReceiptInAppPurchase *iap in receipt.inAppPurchases)
	{
		if ([iap.productID isEqual:appStoreProductIdentifier] && (
			 (iap.subscriptionExpirationDate == nil) || // not a subscription
			((iap.subscriptionExpirationDate != nil) && (iap.subscriptionExpirationDate.timeIntervalSinceNow > 0)) // subscription valid
		   ))
		{
			offer.state = OCLicenseOfferStateCommitted;
		}
	}
}

#pragma mark - Product request delegate
- (void)refreshProductsWithCompletionHandler:(OCLicenseAppStoreRefreshProductsCompletionHandler)completionHandler
{
	NSMutableSet<OCLicenseAppStoreProductIdentifier> *appStoreIdentifiers = [NSMutableSet new];

	// Build product request
	for (OCLicenseAppStoreItem *item in _items)
	{
		[appStoreIdentifiers addObject:item.identifier];
	}

	OCTLogDebug(@[@"RefreshProducts"], @"Refreshing products %@…", appStoreIdentifiers);

	// Store completion handler and start request if needed
	@synchronized(self)
	{
		OCLicenseAppStoreRefreshProductsCompletionHandler existingCompletionHandler = _productsRefreshCompletionHandler;

		if (existingCompletionHandler != nil)
		{
			_productsRefreshCompletionHandler = ^(NSError *error) {
				existingCompletionHandler(error);
				completionHandler(error);
			};

			return;
		}
		else
		{
			_productsRefreshCompletionHandler = [completionHandler copy];
		}

		_request = [[SKProductsRequest alloc] initWithProductIdentifiers:appStoreIdentifiers];
		_request.delegate = self;

		[_request start];
	}
}

- (void)refreshProductsIfNeededWithCompletionHandler:(OCLicenseAppStoreRefreshProductsCompletionHandler)completionHandler
{
	OCTLogDebug(@[@"RefreshProducts"], @"Refreshing products if needed");

	if ((self.offers.count == 0) && self.purchasesAllowed)
	{
		OCTLogDebug(@[@"RefreshProducts"], @"Refreshing products as there are no offers available");

		[self refreshProductsWithCompletionHandler:completionHandler];
	}
	else
	{
		OCTLogDebug(@[@"RefreshProducts"], @"Offers available - not refreshing products");

		completionHandler(nil);
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	OCTLogDebug(@[@"RefreshProducts"], @"Request %@ received response %@", request, response);

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

	[self recomputeOffers];
}

- (void)requestDidFinish:(SKRequest *)request
{
	// Called last on success (not called on error)

	@synchronized(self)
	{
		OCTLogDebug(@[@"Request"], @"App Store request %@ finished", request);

		if (_productsRefreshCompletionHandler != nil)
		{
			_productsRefreshCompletionHandler(nil);
			_productsRefreshCompletionHandler = nil;
		}

		if (request == _request)
		{
			_request = nil;
		}
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	// Called last on error
	@synchronized(self)
	{
		OCTLogError(@[@"Request"], @"App Store request %@ failed with error %@", request, error);

		if (_productsRefreshCompletionHandler != nil)
		{
			_productsRefreshCompletionHandler(error);
			_productsRefreshCompletionHandler = nil;
		}

		if (request == _request)
		{
			_request = nil;
		}
	}
}

#pragma mark - Payment
- (void)requestPaymentFor:(SKProduct *)product
{
	SKPayment *payment;

	OCTLogDebug(@[@"Payment"], @"Requesting payment for %@ (productIdentifier=%@)", product, product.productIdentifier);

	if ((product != nil) && ((payment = [SKPayment paymentWithProduct:product]) != nil))
	{
		[SKPaymentQueue.defaultQueue addPayment:payment];
	}
}

#pragma mark - Payment transaction observation
// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	OCTLogDebug(@[@"Payment"], @"Payment queue updated with transactions %@", transactions);

	for (SKPaymentTransaction *originalTransaction in transactions)
	{
		OCLicenseOfferState offerState = OCLicenseOfferStateUncommitted;
		SKPaymentTransaction *transaction = originalTransaction;
		NSError *error = nil;
		BOOL finishTransaction = NO;

		OCTLogDebug(@[@"Payment"], @"Handling transaction %@ (%@)", transaction, transaction.transactionIdentifier);

		// Restored transaction => use the original transaction if available
		if ((transaction.transactionState == SKPaymentTransactionStateRestored) && (transaction.originalTransaction != nil))
		{
			// Transaction has been restored
			transaction = transaction.originalTransaction;
			finishTransaction = YES;

			OCTLogDebug(@[@"Payment"], @"Transaction has been restored - henceforth working with originalTransaction %@ (%@)", transaction, transaction.transactionIdentifier);
		}

		// Fall back to any existing offer state
		OCLicenseAppStoreProductIdentifier appStoreProductIdentifier = transaction.payment.productIdentifier;

		if (appStoreProductIdentifier != nil)
		{
			@synchronized(self)
			{
				if (_offerStateByAppStoreProductIdentifier[appStoreProductIdentifier] != nil)
				{
					offerState = _offerStateByAppStoreProductIdentifier[appStoreProductIdentifier].unsignedIntegerValue;
				}
			}
		}

		// Translate transaction to offer state
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchasing:
				offerState = OCLicenseOfferStateInProgress;

				OCTLogDebug(@[@"Payment"], @"TransactionState=Purchasing for %@ (%@)", transaction, transaction.transactionIdentifier);

				// Calling finishTransaction here throws an exception (via documentation)
			break;

			case SKPaymentTransactionStateDeferred:
				offerState = OCLicenseOfferStateInProgress;

				OCTLogDebug(@[@"Payment"], @"TransactionState=Deferred for %@ (%@)", transaction, transaction.transactionIdentifier);
			break;

			case SKPaymentTransactionStatePurchased:
				offerState = OCLicenseOfferStateCommitted;
				finishTransaction = YES;

				OCTLogDebug(@[@"Payment"], @"TransactionState=Purchased for %@ (%@)", transaction, transaction.transactionIdentifier);
			break;

			case SKPaymentTransactionStateFailed:
				error = transaction.error;

				offerState = OCLicenseOfferStateUncommitted;
				finishTransaction = YES;

				OCTLogError(@[@"Payment"], @"TransactionState=Failed for %@ (%@), error=%@", transaction, transaction.transactionIdentifier, transaction.error);
			break;

			case SKPaymentTransactionStateRestored:
				finishTransaction = YES;

				OCTLogWarning(@[@"Payment"], @"TransactionState=Restored for %@ (%@) - original: %@ (%@)", transaction, transaction.transactionIdentifier, originalTransaction, originalTransaction.transactionIdentifier);
			break;
		}

		// Store new offer state
		if (appStoreProductIdentifier != nil)
		{
			@synchronized(self)
			{
				_offerStateByAppStoreProductIdentifier[appStoreProductIdentifier] = @(offerState);

				// Update offer
				OCLicenseOfferIdentifier offerID = AppStoreOfferIdentifier(appStoreProductIdentifier);

				for (OCLicenseOffer *offer in self.offers)
				{
					if ([offer.identifier isEqual:offerID])
					{
						[self _updateStateForOffer:offer withAppStoreProductIdentifier:appStoreProductIdentifier];
						break;
					}
				}
			}
		}

		// Finish transaction and remove it from the SKPaymentQueue
		OCTLogDebug(@[@"Payment"], @"Finishing (%d) transaction %@ (%@)", finishTransaction, originalTransaction, originalTransaction.transactionIdentifier);

		if (finishTransaction)
		{
			[SKPaymentQueue.defaultQueue finishTransaction:originalTransaction];
		}

		// Reload receipt
		if ((appStoreProductIdentifier != nil) && finishTransaction && (offerState == OCLicenseOfferStateCommitted))
		{
			OCTLogDebug(@[@"Payment"], @"Reloading receipt");
			[self loadReceipt];

			[self _ipcNotifyToReloadReceipt];
		}

		// Report errors
		if ((appStoreProductIdentifier != nil) && finishTransaction)
		{
			if (_commitErrorHandlerByProductIdentifier[appStoreProductIdentifier] != nil)
			{
				((OCLicenseOfferCommitErrorHandler)_commitErrorHandlerByProductIdentifier[appStoreProductIdentifier])(error);

				[_commitErrorHandlerByProductIdentifier removeObjectForKey:appStoreProductIdentifier];
			}
		}
	}

	[self recomputeEntitlements];
}

#pragma mark - Restore IAPs
- (void)restorePurchasesWithCompletionHandler:(OCLicenseAppStoreRestorePurchasesCompletionHandler)completionHandler
{
	OCTLogDebug(@[@"RestorePurchases"], @"Restoring purchases…");

	if (self.isVolumePurchase)
	{
		OCTLogDebug(@[@"RestorePurchases"], @"Cancelling purchase restore (VPP detected)…");

		if (completionHandler != nil)
		{
			completionHandler(nil);
		}

		return;
	}

	@synchronized(self)
	{
		OCLicenseAppStoreRestorePurchasesCompletionHandler existingCompletionHandler = nil;

		if ((existingCompletionHandler = _restorePurchasesCompletionHandler) != nil)
		{
			completionHandler = [completionHandler copy];

			_restorePurchasesCompletionHandler = [^(NSError *error) {
				existingCompletionHandler(error);
				completionHandler(error);
			} copy];
		}
		else
		{
			_restorePurchasesCompletionHandler = [completionHandler copy];
		}

		[SKPaymentQueue.defaultQueue restoreCompletedTransactions];
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	OCTLogError(@[@"RestorePurchases"], @"Payment queue restore failed with error %@", error);

	@synchronized(self)
	{
		[self loadReceipt];
		[self _ipcNotifyToReloadReceipt];

		if (_restorePurchasesCompletionHandler != nil)
		{
			_restorePurchasesCompletionHandler(error);
			_restorePurchasesCompletionHandler = nil;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	OCTLogDebug(@[@"RestorePurchases"], @"Payment queue restore completed successfully");

	@synchronized(self)
	{
		[self loadReceipt];
		[self _ipcNotifyToReloadReceipt];

		if (_restorePurchasesCompletionHandler != nil)
		{
			_restorePurchasesCompletionHandler(nil);
			_restorePurchasesCompletionHandler = nil;
		}
	}
}

+ (NSArray<OCLogTagName> *)logTags
{
	return (@[@"Licensing", @"AppStore"]);
}

- (NSArray<OCLogTagName> *)logTags
{
	return (@[@"Licensing", @"AppStore"]);
}

@end

@implementation OCLicenseManager (AppStore)

+ (OCLicenseAppStoreProvider *)appStoreProvider
{
	return ((OCLicenseAppStoreProvider *)[self.sharedLicenseManager providerForIdentifier:OCLicenseProviderIdentifierAppStore]);
}

@end

OCLicenseProviderIdentifier OCLicenseProviderIdentifierAppStore = @"app-store";

NSErrorDomain OCLicenseAppStoreProviderErrorDomain = @"OCLicenseAppStoreProviderError";
