//
//  OCLicenseEnterpriseProvider.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 05.12.19.
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
#import "OCLicenseEntitlement.h"
#import "OCLicenseEnterpriseProvider.h"

@implementation OCLicenseEnterpriseProvider

#pragma mark - Init
- (instancetype)initWithUnlockedProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)unlockedProductIdentifiers
{
	if ((self = [super initWithIdentifier:OCLicenseProviderIdentifierEnterprise]) != nil)
	{
		_unlockedProductIdentifiers = unlockedProductIdentifiers;
		self.localizedName = OCLocalized(@"Enterprise");
	}

	return (self);
}

- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	NSMutableArray<OCLicenseEntitlement *> *entitlements = [NSMutableArray new];

	for (OCLicenseProductIdentifier productIdentifier in self.unlockedProductIdentifiers)
	{
		OCLicenseEntitlement *entitlement;

		entitlement = [OCLicenseEntitlement entitlementWithIdentifier:nil forProduct:productIdentifier type:OCLicenseTypePurchase valid:YES expiryDate:nil applicability:@"core.connection.serverEdition == \"Enterprise\" || bookmark.userInfo.statusInfo.edition == \"Enterprise\""];

		[entitlements addObject:entitlement];
	}

	self.entitlements = (entitlements.count > 0) ? entitlements : nil;

	completionHandler(self, nil);
}

@end

OCLicenseProviderIdentifier OCLicenseProviderIdentifierEnterprise = @"enterprise";
