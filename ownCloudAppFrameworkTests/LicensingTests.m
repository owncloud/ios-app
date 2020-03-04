//
//  LicensingTests.m
//  LicensingTests
//
//  Created by Felix Schwarz on 21.11.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ownCloudApp/ownCloudApp.h>

@interface LicensingTests : XCTestCase

@end

typedef void(^LicenseProviderBlock)(OCLicenseProvider *provider, OCLicenseProviderCompletionHandler completionHandler);

@interface TestProvider : OCLicenseProvider

@property(copy) LicenseProviderBlock startBlock;
@property(copy) LicenseProviderBlock stopBlock;

@end

@implementation TestProvider

- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	if (self.startBlock != nil)
	{
		self.startBlock(self, completionHandler);
	}
}

- (void)stopProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	if (self.stopBlock != nil)
	{
		self.stopBlock(self, completionHandler);
	}
}

@end

@implementation LicensingTests

- (void)_registerFeaturesAndProductsInManager:(OCLicenseManager *)manager
{
	// Register features
	[manager registerFeature:[OCLicenseFeature featureWithIdentifier:@"feature-1"]];
	[manager registerFeature:[OCLicenseFeature featureWithIdentifier:@"feature-2"]];

	// Register products
	[manager registerProduct:[OCLicenseProduct productWithIdentifier:@"single.feature-1" name:@"Feature 1" description:@"Unlock Feature 1" contents:@[
		@"feature-1"
	]]];

	[manager registerProduct:[OCLicenseProduct productWithIdentifier:@"single.feature-2" name:@"Feature 2" description:@"Unlock Feature 2" contents:@[
		@"feature-2"
	]]];

	[manager registerProduct:[OCLicenseProduct productWithIdentifier:@"bundle.feature-1-2" name:@"Both Features" description:@"Unlock Both Features" contents:@[
		@"feature-1",
		@"feature-2"
	]]];
}

- (void)testFeatureContainedInProductsAssociation
{
	XCTestExpectation *expectF1Single1 = [self expectationWithDescription:@"Expect feature-1 in single.feature-1"];
	XCTestExpectation *expectF1Bundle = [self expectationWithDescription:@"Expect feature-1 in bundle.feature-1-2"];
	XCTestExpectation *expectF2Single2 = [self expectationWithDescription:@"Expect feature-2 in single.feature-2"];
	XCTestExpectation *expectF2Bundle = [self expectationWithDescription:@"Expect feature-2 in bundle.feature-1-2"];

	OCLicenseManager *manager = [OCLicenseManager new];

	[self _registerFeaturesAndProductsInManager:manager];

	[manager.queue async:^(dispatch_block_t  _Nonnull completionHandler) {
		for (OCLicenseProduct *product in [manager featureWithIdentifier:@"feature-1"].containedInProducts)
		{
			if ([product.identifier isEqualToString:@"single.feature-1"])
			{
				[expectF1Single1 fulfill];
			}
			else if ([product.identifier isEqualToString:@"bundle.feature-1-2"])
			{
				[expectF1Bundle fulfill];
			}
			else
			{
				XCTFail(@"Unexpected product %@ for feature 1", product.identifier);
			}
		}

		for (OCLicenseProduct *product in [manager featureWithIdentifier:@"feature-2"].containedInProducts)
		{
			if ([product.identifier isEqualToString:@"single.feature-2"])
			{
				[expectF2Single2 fulfill];
			}
			else if ([product.identifier isEqualToString:@"bundle.feature-1-2"])
			{
				[expectF2Bundle fulfill];
			}
			else
			{
				XCTFail(@"Unexpected product %@ for feature 2", product.identifier);
			}
		}
	}];

	[self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testLicenseProviderStartStop
{
	XCTestExpectation *expectStart = [self expectationWithDescription:@"Expect start"];
	XCTestExpectation *expectStop = [self expectationWithDescription:@"Expect stop"];

	OCLicenseManager *manager = [OCLicenseManager new];
	TestProvider *provider = [TestProvider new];

	provider.startBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		[expectStart fulfill];
	};

	provider.stopBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		[expectStop fulfill];
	};

	[self _registerFeaturesAndProductsInManager:manager];

	[manager addProvider:provider];
	[manager removeProvider:provider];

	[self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testUnlock
{
	XCTestExpectation *expectFeature1PermissionDenied = [self expectationWithDescription:@"Expect F1 permission denied"];
	XCTestExpectation *expectFeature1PermissionGranted = [self expectationWithDescription:@"Expect F1 permission granted"];
	XCTestExpectation *expectProduct1PermissionDenied = [self expectationWithDescription:@"Expect P1 permission denied"];
	XCTestExpectation *expectProduct1PermissionGranted = [self expectationWithDescription:@"Expect P1 permission granted"];

	XCTestExpectation *expectFeature2PermissionDenied = [self expectationWithDescription:@"Expect F2 permission denied"];
	XCTestExpectation *expectFeature2PermissionGranted = [self expectationWithDescription:@"Expect F2 permission granted"];
	XCTestExpectation *expectProduct2PermissionDenied = [self expectationWithDescription:@"Expect P2 permission denied"];
	XCTestExpectation *expectProduct2PermissionGranted = [self expectationWithDescription:@"Expect P2 permission granted"];

	OCLicenseManager *manager = [OCLicenseManager new];
	OCLicenseEnvironment *environment = [OCLicenseEnvironment environmentWithIdentifier:@"environment" hostname:@"demo.owncloud.org" certificate:nil attributes:nil];
	TestProvider *provider = [TestProvider new];

	[self _registerFeaturesAndProductsInManager:manager];

	provider.startBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		provider.entitlements = @[
			[OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:@"single.feature-1" type:OCLicenseTypePurchase valid:YES expiryDate:nil applicability:nil]
		];

		completionHandler(provider, nil);
	};

	provider.stopBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		provider.entitlements = nil;

		completionHandler(provider, nil);
	};

	dispatch_group_t addEntitlementGroup = dispatch_group_create();

	// Observe feature 1
	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:nil features:@[ @"feature-1" ] inEnvironment:environment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectFeature1PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectFeature1PermissionGranted fulfill];
		}
	}];

	// Observe product 1
	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:@[ @"single.feature-1" ] features:nil inEnvironment:environment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectProduct1PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectProduct1PermissionGranted fulfill];
		}
	}];

	// Observe feature 2
	expectFeature2PermissionGranted.inverted = YES;

	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:nil features:@[ @"feature-2" ] inEnvironment:environment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectFeature2PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectFeature2PermissionGranted fulfill];
		}
	}];

	// Observe product 2
	expectProduct2PermissionGranted.inverted = YES;

	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:@[ @"single.feature-2" ] features:nil inEnvironment:environment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectProduct2PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectProduct2PermissionGranted fulfill];
		}
	}];

	// Add provider once all observers received their denied status update
	dispatch_group_notify(addEntitlementGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		[manager addProvider:provider];
	});

	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUnlockWithLimitedApplicability
{
	XCTestExpectation *expectFeature1PermissionDenied = [self expectationWithDescription:@"Expect F1 permission denied"];
	XCTestExpectation *expectFeature1PermissionGranted = [self expectationWithDescription:@"Expect F1 permission granted"];

	XCTestExpectation *expectProduct1PermissionDenied = [self expectationWithDescription:@"Expect P1 permission denied"];
	XCTestExpectation *expectProduct1PermissionGranted = [self expectationWithDescription:@"Expect P1 permission granted"];

	OCLicenseManager *manager = [OCLicenseManager new];
	OCLicenseEnvironment *orgEnvironment = [OCLicenseEnvironment environmentWithIdentifier:@"org" hostname:@"demo.owncloud.org" certificate:nil attributes:nil];
	OCLicenseEnvironment *comEnvironment = [OCLicenseEnvironment environmentWithIdentifier:@"com" hostname:@"demo.owncloud.com" certificate:nil attributes:nil];
	TestProvider *provider = [TestProvider new];

	[self _registerFeaturesAndProductsInManager:manager];

	provider.startBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		provider.entitlements = @[
			[OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:@"single.feature-1" type:OCLicenseTypePurchase valid:YES expiryDate:nil applicability:@"identifier = \"com\""]
		];

		completionHandler(provider, nil);
	};

	provider.stopBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		provider.entitlements = nil;

		completionHandler(provider, nil);
	};

	dispatch_group_t addEntitlementGroup = dispatch_group_create();

	// Observe feature 1 in orgEnvironment
	dispatch_group_enter(addEntitlementGroup);

	expectFeature1PermissionGranted.inverted = YES;

	[manager observeProducts:nil features:@[ @"feature-1" ] inEnvironment:orgEnvironment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectFeature1PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectFeature1PermissionGranted fulfill];
		}
	}];

	// Observe product 1 in comEnvironment
	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:@[ @"single.feature-1" ] features:nil inEnvironment:comEnvironment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectProduct1PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectProduct1PermissionGranted fulfill];
		}
	}];

	// Add provider once all observers received their denied status update
	dispatch_group_notify(addEntitlementGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		[manager addProvider:provider];
	});

	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUnlockWithExpiration
{
	XCTestExpectation *expectFeature1PermissionDenied = [self expectationWithDescription:@"Expect F1 permission denied"];
	XCTestExpectation *expectFeature1PermissionGranted = [self expectationWithDescription:@"Expect F1 permission granted"];
	XCTestExpectation *expectFeature1PermissionExpired = [self expectationWithDescription:@"Expect F1 permission denied again"];

	XCTestExpectation *expectProduct1PermissionDenied = [self expectationWithDescription:@"Expect P1 permission denied"];
	XCTestExpectation *expectProduct1PermissionGranted = [self expectationWithDescription:@"Expect P1 permission granted"];
	XCTestExpectation *expectProduct1PermissionExpired = [self expectationWithDescription:@"Expect P1 permission denied again"];

	OCLicenseManager *manager = [OCLicenseManager new];
	OCLicenseEnvironment *environment = [OCLicenseEnvironment environmentWithIdentifier:@"environment" hostname:@"demo.owncloud.org" certificate:nil attributes:nil];
	TestProvider *provider = [TestProvider new];

	[self _registerFeaturesAndProductsInManager:manager];

	provider.startBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		provider.entitlements = @[
			[OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:@"single.feature-1" type:OCLicenseTypePurchase valid:YES expiryDate:[NSDate dateWithTimeIntervalSinceNow:3] applicability:nil]
		];

		completionHandler(provider, nil);
	};

	provider.stopBlock = ^(OCLicenseProvider *provider, void (^completionHandler)(OCLicenseProvider *provider, NSError * _Nullable error)) {
		provider.entitlements = nil;

		completionHandler(provider, nil);
	};

	dispatch_group_t addEntitlementGroup = dispatch_group_create();

	// Observe feature 1
	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:nil features:@[ @"feature-1" ] inEnvironment:environment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectFeature1PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectFeature1PermissionGranted fulfill];
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusExpired)
		{
			[expectFeature1PermissionExpired fulfill];
		}
	}];

	// Observe product 1
	dispatch_group_enter(addEntitlementGroup);
	[manager observeProducts:@[ @"single.feature-1" ] features:nil inEnvironment:environment withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus) {
		if (authorizationStatus == OCLicenseAuthorizationStatusDenied)
		{
			[expectProduct1PermissionDenied fulfill];
			dispatch_group_leave(addEntitlementGroup);
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusGranted)
		{
			[expectProduct1PermissionGranted fulfill];
		}

		if (authorizationStatus == OCLicenseAuthorizationStatusExpired)
		{
			[expectProduct1PermissionExpired fulfill];
		}
	}];

	// Add provider once all observers received their denied status update
	dispatch_group_notify(addEntitlementGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		[manager addProvider:provider];
	});

	[self waitForExpectationsWithTimeout:10 handler:nil];

}

- (NSArray <OCLicenseAppStoreItem *> *)_appStoreItems
{
	return (@[
		[OCLicenseAppStoreItem trialWithAppStoreIdentifier:@"trial.pro.30days" trialDuration:[[OCLicenseDuration alloc] initWithUnit:OCLicenseDurationUnitDay length:30] productIdentifier:@"bundle.pro"],
		[OCLicenseAppStoreItem nonConsumableIAPWithAppStoreIdentifier:@"single.documentsharing" productIdentifier:@"single.documentsharing"],
		[OCLicenseAppStoreItem subscriptionWithAppStoreIdentifier:@"bundle.pro" productIdentifier:@"bundle.pro" trialDuration:[[OCLicenseDuration alloc] initWithUnit:OCLicenseDurationUnitDay length:30]]
	]);
}

- (void)_registerAppStoreFeaturesAndProductsInManager:(OCLicenseManager *)manager
{
	// Register features
	[manager registerFeature:[OCLicenseFeature featureWithIdentifier:@"documentsharing"]];

	// Register products
	[manager registerProduct:[OCLicenseProduct productWithIdentifier:@"single.documentsharing" name:@"Document Sharing" description:@"Unlock Document Sharing" contents:@[
		@"documentsharing"
	]]];

	[manager registerProduct:[OCLicenseProduct productWithIdentifier:@"bundle.pro" name:@"Pro Bundle" description:@"Unlock Pro Features" contents:@[
		@"documentsharing"
	]]];
}

- (void)testAppStoreProductRequest
{
	NSArray <OCLicenseAppStoreItem *> *appStoreItems = [self _appStoreItems];
	OCLicenseAppStoreProvider *provider = [[OCLicenseAppStoreProvider alloc] initWithItems:appStoreItems];

	XCTestExpectation *expectResponse = [self expectationWithDescription:@"Expect response"];

	[provider startProvidingWithCompletionHandler:^(OCLicenseProvider *provider, NSError * _Nullable error) {
		OCLogDebug(@"error=%@, offers=%@", error, provider.offers);

		XCTAssert((error==nil), @"Error: %@", error);
		XCTAssert((provider.offers!=nil), @"No offers!");
		XCTAssert((provider.offers.count==appStoreItems.count), @"Incomplete offers!");

		[expectResponse fulfill];
	}];

	[self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testOfferObservation
{
	OCLicenseManager *manager = [OCLicenseManager new];
	NSArray <OCLicenseAppStoreItem *> *appStoreItems = [self _appStoreItems];
	OCLicenseAppStoreProvider *provider = [[OCLicenseAppStoreProvider alloc] initWithItems:appStoreItems];

	XCTestExpectation *expectNoOffers = [self expectationWithDescription:@"Expect no offers"];
	__block XCTestExpectation *expectOffers = [self expectationWithDescription:@"Expect offers"];
	XCTestExpectation *expectNoOffersAgain = [self expectationWithDescription:@"Expect no offers again"];

	[self _registerAppStoreFeaturesAndProductsInManager:manager];

	[manager observeOffersForProducts:@[@"bundle.pro"] features:nil withOwner:self updateHandler:^(OCLicenseObserver * _Nonnull observer, BOOL isInitial, NSArray<OCLicenseOffer *> * _Nonnull offers) {
		OCLogDebug(@"observer=%@, isInitial=%d, offers=%@", observer, isInitial, offers);

		if (isInitial)
		{
			[manager addProvider:provider];

			if (offers.count == 0)
			{
				[expectNoOffers fulfill];
			}
		}
		else
		{
			if (offers.count > 0)
			{
				[expectOffers fulfill];
				expectOffers = nil;

				[manager removeProvider:provider];
			}
			else if (expectOffers == nil)
			{
				[expectNoOffersAgain fulfill];
			}
		}
	}];

	[self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
