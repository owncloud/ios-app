//
//  OCLicenseQAProvider.m
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "OCLicenseQAProvider.h"
#import "OCLicenseEntitlement.h"
#import "OCLicenseProduct.h"
#import "OCLicenseFeature.h"
#import "OCLicenseManager.h"

static OCLicenseQAProvider *sharedProvider = nil;

@implementation OCLicenseQAProvider
{
	id<OCLicenseQAProviderDelegate> _delegate;
}

#pragma mark - Shared instance
+ (void)setSharedProvider:(OCLicenseQAProvider *)provider
{
	sharedProvider = provider;
}

+ (OCLicenseQAProvider *)sharedProvider
{
	return (sharedProvider);
}

#pragma mark - Init
- (instancetype)initWithUnlockedProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)unlockedProductIdentifiers delegate:(id<OCLicenseQAProviderDelegate>)delegate
{
	if ((self = [super initWithIdentifier:OCLicenseProviderIdentifierQA]) != nil)
	{
		_unlockedProductIdentifiers = unlockedProductIdentifiers;
		_delegate = delegate;

		self.localizedName = @"QA";

		[OCLicenseQAProvider setSharedProvider:self];
	}

	return (self);
}

#pragma mark - Providing and updating entitlements
- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	[self updateEntitlements];

	completionHandler(self, nil);
}

- (void)updateEntitlements
{
	NSMutableArray<OCLicenseEntitlement *> *entitlements = [NSMutableArray new];

	if (OCLicenseQAProvider.isQAUnlockEnabled && OCLicenseQAProvider.isQAUnlockPossible)
	{
		for (OCLicenseProductIdentifier productIdentifier in self.unlockedProductIdentifiers)
		{
			OCLicenseEntitlement *entitlement;

			entitlement = [OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:productIdentifier type:OCLicenseTypePurchase valid:YES expiryDate:nil applicability:nil]; // Valid entitlement for all environments

			[entitlements addObject:entitlement];
		}
	}

	self.entitlements = (entitlements.count > 0) ? entitlements : nil;
}

#pragma mark - Unlock message
- (nullable OCLicenseProduct *)_unlockedProductForFeature:(OCLicenseFeatureIdentifier)featureIdentifier
{
	for (OCLicenseProductIdentifier productIdentifier in self.unlockedProductIdentifiers)
	{
		OCLicenseProduct *product;

		if ((product = [self.manager productWithIdentifier:productIdentifier]) != nil)
		{
			if (featureIdentifier != nil)
			{
				if ([product.contents containsObject:featureIdentifier])
				{
					return (product);
				}
			}
			else
			{
				return (product);
			}
		}
	}

	return (nil);
}

- (NSString *)inAppPurchaseMessageForFeature:(OCLicenseFeatureIdentifier)featureIdentifier
{
	NSString *iapMessage = nil;
	OCLicenseProduct *unlockedProduct = nil;
	OCLicenseFeature *feature = nil;

	if (featureIdentifier != nil)
	{
		feature = [self.manager featureWithIdentifier:featureIdentifier];
	}

	if ((unlockedProduct = [self _unlockedProductForFeature:featureIdentifier]) != nil)
	{
		if (OCLicenseQAProvider.isQAUnlockEnabled && OCLicenseQAProvider.isQAUnlockPossible)
		{
			NSString *subject = (feature.localizedName != nil) ? feature.localizedName : unlockedProduct.localizedName;
			iapMessage = [NSString stringWithFormat:OCLocalized(@"%@ unlocked for QA."), subject];
		}
	}

	return (iapMessage);
}

#pragma mark -
+ (BOOL)isQAUnlockEnabled
{
	return ([OCAppIdentity.sharedAppIdentity.userDefaults boolForKey:@"qa.license-unlock-enabled"]);
}

+ (void)setIsQAUnlockEnabled:(BOOL)isQAUnlockEnabled
{
	[OCAppIdentity.sharedAppIdentity.userDefaults setBool:isQAUnlockEnabled forKey:@"qa.license-unlock-enabled"];
	[OCLicenseQAProvider.sharedProvider updateEntitlements];
}

- (BOOL)isQAUnlockPossible
{
	return ([_delegate isQALicenseUnlockPossible]);
}

+ (BOOL)isQAUnlockPossible
{
	return ([OCLicenseQAProvider.sharedProvider isQAUnlockPossible]);
}

@end

OCLicenseProviderIdentifier OCLicenseProviderIdentifierQA = @"qa";
