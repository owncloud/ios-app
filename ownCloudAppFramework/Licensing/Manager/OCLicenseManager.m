//
//  OCLicenseManager.m
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

#import "OCLicenseManager.h"
#import "OCLicenseManager+Internal.h"
#import "OCLicenseFeature.h"
#import "OCLicenseProduct.h"
#import "OCLicenseProvider.h"
#import "OCLicenseOffer.h"
#import "OCLicenseEntitlement.h"
#import "OCLicenseObserver.h"

@interface OCLicenseManager ()
{
	// Features
	NSMutableArray<OCLicenseFeature *> *_features;
	NSMutableDictionary<OCLicenseFeatureIdentifier, OCLicenseFeature *> *_featuresByIdentifier;

	// Products
	NSMutableArray<OCLicenseProduct *> *_products;
	NSMutableDictionary<OCLicenseProductIdentifier, OCLicenseProduct *> *_productsByIdentifier;

	BOOL _needsProductFeatureRewiring;

	// Providers
	NSMutableArray<OCLicenseProvider *> *_providers;

	NSMutableSet<OCLicenseOffer *> *_offers;
	NSMutableSet<OCLicenseEntitlement *> *_entitlements;
	BOOL _needsRebuildFromProviders;

	// Observers
	NSMapTable<id, NSMutableArray<OCLicenseObserver *> *> *_observersByOwner;
	NSHashTable<OCLicenseObserver *> *_observers;
	BOOL _needsObserverUpdate;

	NSDate *_nextEarliestExpectedChangeDate;
}

@end

@implementation OCLicenseManager

+ (OCLicenseManager *)sharedLicenseManager
{
	static dispatch_once_t onceToken;
	static OCLicenseManager *sharedLicenseManager;

	dispatch_once(&onceToken, ^{
		sharedLicenseManager = [OCLicenseManager new];
	});

	return (sharedLicenseManager);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		_queue = [OCAsyncSequentialQueue new];

		_features = [NSMutableArray new];
		_featuresByIdentifier = [NSMutableDictionary new];

		_products = [NSMutableArray new];
		_productsByIdentifier = [NSMutableDictionary new];

		_providers = [NSMutableArray new];

		_offers = [NSMutableSet new];
		_entitlements = [NSMutableSet new];

		_observersByOwner = [NSMapTable weakToStrongObjectsMapTable];
		_observers = [NSHashTable weakObjectsHashTable];
	}

	return (self);
}

- (void)dealloc
{
	// Remove observers
	for (OCLicenseProvider *provider in _providers)
	{
		[provider removeObserver:self forKeyPath:@"offers" context:(__bridge void *)self];
		[provider removeObserver:self forKeyPath:@"entitlements" context:(__bridge void *)self];
	}

	_providers = nil;
}

#pragma mark - Feature/product registration
- (void)registerFeature:(OCLicenseFeature *)feature
{
	@synchronized(self)
	{
		[_features addObject:feature];
		_featuresByIdentifier[feature.identifier] = feature;

		feature.manager = self;

		[self setNeedsProductFeatureRewiring];
	}
}

- (void)registerProduct:(OCLicenseProduct *)product
{
	@synchronized(self)
	{
		[_products addObject:product];
		_productsByIdentifier[product.identifier] = product;

		product.manager = self;

		[self setNeedsProductFeatureRewiring];
	}
}

#pragma mark - Feature/product resolution
- (nullable OCLicenseProduct *)productWithIdentifier:(OCLicenseProductIdentifier)productIdentifier
{
	OCLicenseProduct *product = nil;

	@synchronized (self)
	{
		product = _productsByIdentifier[productIdentifier];
	}

	return (product);
}

- (nullable OCLicenseFeature *)featureWithIdentifier:(OCLicenseFeatureIdentifier)featureIdentifier
{
	OCLicenseFeature *feature = nil;

	@synchronized (self)
	{
		feature = _featuresByIdentifier[featureIdentifier];
	}

	return (feature);
}

- (nullable NSArray<OCLicenseOffer *> *)_orderedOffersFromOfferSet:(NSMutableSet<OCLicenseOffer *> *)offerSet
{
	return ([offerSet sortedArrayUsingDescriptors:@[
		[NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES],
		[NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES]
	]]);
}

- (nullable NSArray<OCLicenseOffer *> *)offersForFeature:(OCLicenseFeature *)feature
{
	NSMutableSet<OCLicenseOffer *> *offerSet = [NSMutableSet new];

	for (OCLicenseProduct *product in feature.containedInProducts)
	{
		NSArray<OCLicenseOffer *> *offersForProduct;

		if ((offersForProduct = [self offersForProduct:product]) != nil)
		{
			[offerSet addObjectsFromArray:offersForProduct];
		}
	}

	return ([self _orderedOffersFromOfferSet:offerSet]);
}

- (nullable NSArray<OCLicenseOffer *> *)offersForProduct:(OCLicenseProduct *)product
{
	NSMutableSet<OCLicenseOffer *> *offerSet = [NSMutableSet new];

	@synchronized(self)
	{
		for (OCLicenseOffer *offer in _offers)
		{
			if ((offer.productIdentifier != nil) && [offer.productIdentifier isEqual:product.identifier])
			{
				[offerSet addObject:offer];
			}
		}
	}

	return ([self _orderedOffersFromOfferSet:offerSet]);
}

- (nullable NSArray<OCLicenseFeature *> *)featuresWithOffers:(BOOL)withOffers
{
	NSMutableArray <OCLicenseFeature *> *features = [NSMutableArray new];

	@synchronized (self)
	{
		for (OCLicenseFeature *feature in _features)
		{
			if (!withOffers || (withOffers && ([self offersForFeature:feature].count > 0)))
			{
				[features addObject:feature];
			}
		}
	}

	[features sortUsingDescriptors:@[
		[NSSortDescriptor sortDescriptorWithKey:@"localizedName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]
	]];

	return (features);
}

#pragma mark - Product/feature rewiring
- (void)setNeedsProductFeatureRewiring
{
	[self _setNeedsRun:&_needsProductFeatureRewiring async:^(OCLicenseManager *manager, dispatch_block_t completionHandler) {
		[manager _rewireProductsAndFeaturesWithCompletionHandler:completionHandler];
	}];
}

- (void)_rewireProductsAndFeaturesWithCompletionHandler:(dispatch_block_t)completionHandler
{
	@synchronized(self)
	{
		NSMutableDictionary<OCLicenseFeatureIdentifier, NSHashTable<OCLicenseProduct *> *> *productsByFeatureID = [NSMutableDictionary new];

		for (OCLicenseProduct *product in _products)
		{
			NSMutableArray<OCLicenseFeature *> *features = [NSMutableArray new];

			for (OCLicenseFeatureIdentifier featureIdentifier in product.contents)
			{
				OCLicenseFeature *feature;

				if ((feature = _featuresByIdentifier[featureIdentifier]) != nil)
				{
					[features addObject:feature];
				}

				// Build list of products for each feature
				NSHashTable<OCLicenseProduct *> *productsForFeature = nil;

				if ((productsForFeature = productsByFeatureID[featureIdentifier]) == nil)
				{
					productsForFeature = [NSHashTable weakObjectsHashTable];
					productsByFeatureID[featureIdentifier] = productsForFeature;
				}

				[productsForFeature addObject:product];
			}

			// Set features for product
			product.features = (features.count > 0) ? features : nil;
		}

		// Set products for all features
		for (OCLicenseFeature *feature in _features)
		{
			feature.containedInProducts = productsByFeatureID[feature.identifier];
		}
	}

	completionHandler();
}

#pragma mark - Provider management
- (void)addProvider:(OCLicenseProvider *)provider
{
	@synchronized(self)
	{
		[_providers addObject:provider];
		[provider addObserver:self forKeyPath:@"offers" options:0 context:(__bridge void *)self];
		[provider addObserver:self forKeyPath:@"entitlements" options:0 context:(__bridge void *)self];

		provider.manager = self;

		[provider startProvidingWithCompletionHandler:^(OCLicenseProvider *provider, NSError * _Nullable error) {
			if (error != nil)
			{
				OCLogError(@"Error starting license provider %@: %@", provider, error);
			}
		}];

		[self setNeedsRebuildFromProviders];
	}
}

- (void)removeProvider:(OCLicenseProvider *)provider
{
	@synchronized(self)
	{
		[provider removeObserver:self forKeyPath:@"offers" context:(__bridge void *)self];
		[provider removeObserver:self forKeyPath:@"entitlements" context:(__bridge void *)self];

		[provider stopProvidingWithCompletionHandler:^(OCLicenseProvider *provider, NSError * _Nullable error) {
			if (error != nil)
			{
				OCLogError(@"Error stopping license provider %@: %@", provider, error);
			}
		}];

		provider.manager = nil;

		[_providers removeObject:provider];

		[self setNeedsRebuildFromProviders];
	}
}

- (nullable OCLicenseProvider *)providerForIdentifier:(OCLicenseProviderIdentifier)providerIdentifier
{
	OCLicenseProvider *result = nil;

	@synchronized(self)
	{
		for (OCLicenseProvider *provider in _providers)
		{
			if ([provider.identifier isEqual:providerIdentifier])
			{
				result = provider;
				break;
			}
		}
	}

	return (result);
}

#pragma mark - Transactions
- (void)retrieveAllTransactionsWithCompletionHandler:(void(^)(NSError *error, NSArray<NSArray<OCLicenseTransaction *> *> *transactionsByProvider))completionHandler
{
	dispatch_group_t retrieveGroup = dispatch_group_create();
	__block NSMutableArray <NSArray<OCLicenseTransaction *> *> *transactionsByProvider = [NSMutableArray new];
	__block NSError *allError = nil;

	@synchronized(self)
	{
		for (OCLicenseProvider *provider in _providers)
		{
			dispatch_group_enter(retrieveGroup);

			[provider retrieveTransactionsWithCompletionHandler:^(NSError * _Nonnull error, NSArray<OCLicenseTransaction *> * _Nullable transactions) {
				if (error != nil)
				{
					allError = error;
				}

				if (transactions != nil)
				{
					[transactionsByProvider addObject:transactions];
				}

				dispatch_group_leave(retrieveGroup);
			}];
		}
	}

	dispatch_group_notify(retrieveGroup, dispatch_get_main_queue(), ^{
		completionHandler(allError, transactionsByProvider);
	});
}

#pragma mark - Observation
- (void)_addObserver:(OCLicenseObserver *)observer withOwner:(id)owner
{
	@synchronized(self)
	{
		NSMutableArray<OCLicenseObserver *> *observers;

		if ((observers = [_observersByOwner objectForKey:owner]) == nil)
		{
			observers = [NSMutableArray new];
			[_observersByOwner setObject:observers forKey:owner];
		}
		[observers addObject:observer];

		[_observers addObject:observer];

		[self _updateObserver:observer];
	}
}

- (OCLicenseObserver *)observeProducts:(nullable NSArray<OCLicenseProductIdentifier> *)productIdentifiers features:(nullable NSArray<OCLicenseFeatureIdentifier> *)featureIdentifiers inEnvironment:(OCLicenseEnvironment *)environment withOwner:(nullable id)owner updateHandler:(OCLicenseObserverAuthorizationStatusUpdateHandler)updateHandler
{
	OCLicenseObserver *observer = [OCLicenseObserver new];

	if (owner == nil) { owner = self; }

	observer.products = productIdentifiers;
	observer.features = featureIdentifiers;
	observer.environment = environment;
	observer.owner = owner;
	observer.statusUpdateHandler = updateHandler;

	[self _addObserver:observer withOwner:owner];

	return (observer);
}

- (OCLicenseObserver *)observeOffersForProducts:(nullable NSArray<OCLicenseProductIdentifier> *)productIdentifiers features:(nullable NSArray<OCLicenseFeatureIdentifier> *)featureIdentifiers withOwner:(nullable id)owner updateHandler:(OCLicenseObserverOffersUpdateHandler)updateHandler
{
	OCLicenseObserver *observer = [OCLicenseObserver new];

	if (owner == nil) { owner = self; }

	observer.products = productIdentifiers;
	observer.features = featureIdentifiers;
	observer.owner = owner;
	observer.offersUpdateHandler = updateHandler;

	[self _addObserver:observer withOwner:owner];

	return (observer);
}

- (void)stopObserver:(OCLicenseObserver *)observer
{
	@synchronized(self)
	{
		[[_observersByOwner objectForKey:observer.owner] removeObject:observer];
		[_observers removeObject:observer];
	}
}

- (void)setNeedsObserverUpdate
{
	[self _setNeedsRun:&_needsObserverUpdate async:^(OCLicenseManager *manager, dispatch_block_t completionHandler) {
		[manager _updateObserversWithCompletionHandler:completionHandler];
	}];
}

- (void)_updateObserversWithCompletionHandler:(dispatch_block_t)completionHandler
{
	@synchronized(self)
	{
		// Reset entitlements in products and features
		// (will be rebuilt lazely, with features depending on products,
		// so products need to be reset first)
		for (OCLicenseFeature *product in _products)
		{
			product.entitlements = nil;
		}

		for (OCLicenseFeature *feature in _features)
		{
			feature.entitlements = nil;
		}

		// After reset: update observers
		for (OCLicenseObserver *observer in _observers)
		{
			[self _updateObserver:observer];
		}
	}

	completionHandler();
}

- (OCLicenseAuthorizationStatus)_authorizationStatusForEntitlements:(NSArray<OCLicenseEntitlement *> *)entitlements inEnvironment:(OCLicenseEnvironment *)environment
{
	OCLicenseAuthorizationStatus summaryAuthStatus = OCLicenseAuthorizationStatusUnknown;

	OCLogDebug(@"Determining authorization status with entitlements: %@", entitlements);

	// No entitlements => denied
	if (entitlements.count == 0)
	{
		return (OCLicenseAuthorizationStatusDenied);
	}

	// Find greatest authorization status among entitlements and return it as summary value
	for (OCLicenseEntitlement *entitlement in entitlements)
	{
		OCLicenseAuthorizationStatus authStatus;

		authStatus = [entitlement authorizationStatusInEnvironment:environment];

		if (authStatus > summaryAuthStatus)
		{
			summaryAuthStatus = authStatus;
		}
	}

	return (summaryAuthStatus);
}

- (void)_updateObserver:(OCLicenseObserver *)observer
{
	[self _updateAuthorizationStatusForObserver:observer];
	[self _updateOffersForObserver:observer];
}

- (void)_updateOffersForObserver:(OCLicenseObserver *)observer
{
	// Collect products
	NSMutableSet<OCLicenseProductIdentifier> *productIdentifiers = [NSMutableSet new];

	// From observed products
	for (OCLicenseProductIdentifier productIdentifier in observer.products)
	{
		OCLicenseProduct *product;

		if ((product = [self productWithIdentifier:productIdentifier]) != nil)
		{
			[productIdentifiers addObject:productIdentifier];
		}
	}

	// From observed features
	for (OCLicenseFeatureIdentifier featureIdentifier in observer.features)
	{
		OCLicenseFeature *feature;

		if ((feature = [self featureWithIdentifier:featureIdentifier]) != nil)
		{
			for (OCLicenseProduct *product in feature.containedInProducts)
			{
				if (product.identifier != nil)
				{
					[productIdentifiers addObject:product.identifier];
				}
			}
		}
	}

	// Find matching offers
	NSMutableArray <OCLicenseOffer *> *offers = [NSMutableArray new];

	for (OCLicenseOffer *offer in _offers)
	{
		if ([productIdentifiers containsObject:offer.productIdentifier])
		{
			[offers addObject:offer];
		}
	}

	observer.offers = offers;
}

- (void)_updateAuthorizationStatusForObserver:(OCLicenseObserver *)observer
{
	OCLicenseAuthorizationStatus summaryAuthStatus = OCLicenseAuthorizationStatusGranted;

	// Evaluate entitlements from products
	for (OCLicenseProductIdentifier productIdentifier in observer.products)
	{
		OCLicenseProduct *product;

		if ((product = [self productWithIdentifier:productIdentifier]) != nil)
		{
			// Product found => compute authorization status
			OCLicenseAuthorizationStatus authStatus = [self _authorizationStatusForEntitlements:product.entitlements inEnvironment:observer.environment];

			if (authStatus < summaryAuthStatus)
			{
				summaryAuthStatus = authStatus;
			}
		}
		else
		{
			// Product not found => authorization denied
			summaryAuthStatus = OCLicenseAuthorizationStatusDenied;
			break;
		}
	}

	// Evaluate entitlements from features
	if (summaryAuthStatus != OCLicenseAuthorizationStatusDenied)
	{
		for (OCLicenseFeatureIdentifier featureIdentifier in observer.features)
		{
			OCLicenseFeature *feature;

			if ((feature = [self featureWithIdentifier:featureIdentifier]) != nil)
			{
				// Feature found => compute authorization status
				OCLicenseAuthorizationStatus authStatus = [self _authorizationStatusForEntitlements:feature.entitlements inEnvironment:observer.environment];

				if (authStatus < summaryAuthStatus)
				{
					summaryAuthStatus = authStatus;
				}
			}
			else
			{
				// Feature not found => authorization denied
				summaryAuthStatus = OCLicenseAuthorizationStatusDenied;
				break;
			}
		}
	}

	// Update observer's authorization status (which will notify its update handler as needed)
	observer.authorizationStatus = summaryAuthStatus;
}

#pragma mark - Change observation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if (context == (__bridge void *)self)
	{
		OCLicenseProvider *provider;

		if ((provider = OCTypedCast(object, OCLicenseProvider)) != nil)
		{
			if ([keyPath isEqualToString:@"offers"] || [keyPath isEqualToString:@"entitlements"])
			{
				[self setNeedsRebuildFromProviders];
			}
		}
	}
}

#pragma mark - One-off status info
- (OCLicenseAuthorizationStatus)authorizationStatusForFeature:(OCLicenseFeatureIdentifier)featureIdentifier inEnvironment:(OCLicenseEnvironment *)environment
{
	OCLicenseAuthorizationStatus authStatus = OCLicenseAuthorizationStatusUnknown;
	OCLicenseFeature *feature;

	if ((feature = [self featureWithIdentifier:featureIdentifier]) != nil)
	{
		// Feature found => compute authorization status
		authStatus = [self _authorizationStatusForEntitlements:feature.entitlements inEnvironment:environment];
	}

	OCLogDebug(@"Returning authorizationStatus %lu for feature %@ in environment %@…", (unsigned long)authStatus, featureIdentifier, environment);

	return (authStatus);
}

- (OCLicenseAuthorizationStatus)authorizationStatusForProduct:(OCLicenseProductIdentifier)productIdentifier inEnvironment:(OCLicenseEnvironment *)environment
{
	OCLicenseAuthorizationStatus authStatus = OCLicenseAuthorizationStatusUnknown;
	OCLicenseProduct *product;

	if ((product = [self productWithIdentifier:productIdentifier]) != nil)
	{
		// Product found => compute authorization status
		authStatus = [self _authorizationStatusForEntitlements:product.entitlements inEnvironment:environment];
	}

	OCLogDebug(@"Returning authorizationStatus %lu for produt %@ in environment %@…", (unsigned long)authStatus, productIdentifier, environment);

	return (authStatus);
}

#pragma mark - Updates
- (void)setNeedsRebuildFromProviders
{
	[self _setNeedsRun:&_needsRebuildFromProviders async:^(OCLicenseManager *manager, dispatch_block_t completionHandler) {
		[manager _rebuildFromProvidersWithCompletionHandler:completionHandler];
	}];
}

- (void)_rebuildFromProvidersWithCompletionHandler:(dispatch_block_t)completionHandler
{
	OCLogDebug(@"Rebuilding from providers…");

	@synchronized(self)
	{
		NSMutableSet<OCLicenseEntitlement *> *newEntitlements = [NSMutableSet new];
		NSMutableSet<OCLicenseOffer *> *newOffers = [NSMutableSet new];
		BOOL offersUpdated = NO, entitlementsUpdated = NO;

		for (OCLicenseProvider *provider in _providers)
		{
			if (provider.entitlements.count > 0)
			{
				[newEntitlements addObjectsFromArray:provider.entitlements];
			}

			if (provider.offers.count > 0)
			{
				[newOffers addObjectsFromArray:provider.offers];
			}
		}

		if (![_entitlements isEqualToSet:newEntitlements])
		{
			// Entitlements were updated

			// Replace existing entitlements
			[_entitlements setSet:newEntitlements];

			entitlementsUpdated = YES;
		}

		if (![_offers isEqualToSet:newOffers])
		{
			// Offers were updated

			// Replace existing offers
			[_offers setSet:newOffers];

			offersUpdated = YES;
		}

		if (entitlementsUpdated || offersUpdated)
		{
			// Update observers
			[self setNeedsObserverUpdate];
		}


		// Compute the earliest change date (if any)
		NSDate *earliestExpectedChangeDate = nil;

		#define ConsiderAsEarliestChangeDate(dateVar,considerDate) if (considerDate != nil) \
			{ \
				if ((dateVar == nil) || ((considerDate.timeIntervalSinceNow < dateVar.timeIntervalSinceNow) && (considerDate.timeIntervalSinceNow > 0))) \
				{ \
					dateVar = considerDate; \
				} \
			}

		for (OCLicenseEntitlement *entitlement in newEntitlements)
		{
			ConsiderAsEarliestChangeDate(earliestExpectedChangeDate, entitlement.nextStatusChangeDate);
		}

		for (OCLicenseOffer *offer in newOffers)
		{
			ConsiderAsEarliestChangeDate(earliestExpectedChangeDate, offer.fromDate);
			ConsiderAsEarliestChangeDate(earliestExpectedChangeDate, offer.untilDate);
		}

		// Trigger updates at earliestExpectedChangeDate if needed
		if (![earliestExpectedChangeDate isEqual:_nextEarliestExpectedChangeDate])
		{
			_nextEarliestExpectedChangeDate = earliestExpectedChangeDate;

			if (earliestExpectedChangeDate != nil)
			{
				NSTimeInterval timeIntervalSinceNow = earliestExpectedChangeDate.timeIntervalSinceNow;

				if (timeIntervalSinceNow > 0)
				{
					__weak OCLicenseManager *weakManager = self;

					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeIntervalSinceNow + 1.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
						OCLicenseManager *strongManager;

						if ((strongManager = weakManager) != nil)
						{
							if ([strongManager->_nextEarliestExpectedChangeDate isEqual:earliestExpectedChangeDate]) // only perform this if it's still relevant
							{
								// Rebuild from providers so the earliestExpectedChangeDate gets updated
								[strongManager setNeedsRebuildFromProviders];

								// Update observers because their status may have changed
								[strongManager setNeedsObserverUpdate];
							}
						}
					});
				}
			}
		}

		completionHandler();
	}
}

#pragma mark - Update coalescation
- (void)_setNeedsRun:(BOOL *)inOutNeedsRun async:(void(^)(OCLicenseManager *manager, dispatch_block_t completionHandler))block
{
	BOOL triggerRun = NO;

	@synchronized(self)
	{
		if (!*inOutNeedsRun)
		{
			*inOutNeedsRun = YES;

			triggerRun = YES;
		}
	}

	if (triggerRun)
	{
		[_queue async:^(dispatch_block_t  _Nonnull completionHandler) {
			@synchronized(self)
			{
				if (*inOutNeedsRun)
				{
					*inOutNeedsRun = NO;
				}
				else
				{
					completionHandler();
					return;
				}
			}

			block(self, completionHandler);
		}];
	}
}

#pragma mark - Pending refresh tracking
- (void)performAfterCurrentlyPendingRefreshes:(dispatch_block_t)block
{
	OCLogDebug(@"Queuing block %@ for execution after completing pending refreshes…", block);

	[_queue async:^(dispatch_block_t  _Nonnull completionHandler) {
		block();
		completionHandler();
	}];
}

#pragma mark - Log tagging
+ (NSArray<OCLogTagName> *)logTags
{
	return (@[@"Licensing", @"Manager"]);
}

- (NSArray<OCLogTagName> *)logTags
{
	return (@[@"Licensing", @"Manager"]);
}

@end

@implementation OCLicenseManager (Internal)

- (nullable NSArray <OCLicenseEntitlement *> *)_entitlementsForProduct:(OCLicenseProduct *)product
{
	NSMutableArray<OCLicenseEntitlement *> *productEntitlements = nil;

	@synchronized(self)
	{
		for (OCLicenseEntitlement *entitlement in _entitlements)
		{
			if ([entitlement.productIdentifier isEqual:product.identifier])
			{
				if (productEntitlements == nil)
				{
					productEntitlements = [NSMutableArray new];
				}

				[productEntitlements addObject:entitlement];
			}
		}
	}

	return (productEntitlements);
}

@end
