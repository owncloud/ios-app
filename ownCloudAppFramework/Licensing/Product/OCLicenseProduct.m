//
//  OCLicenseProduct.m
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

#import "OCLicenseProduct.h"
#import "OCLicenseManager+Internal.h"

@implementation OCLicenseProduct

+ (instancetype)productWithIdentifier:(OCLicenseProductIdentifier)identifier name:(NSString *)localizedName description:(nullable NSString *)localizedDescription contents:(NSArray<OCLicenseFeatureIdentifier> *)contents
{
	return ([[self alloc] initWithIdentifier:identifier name:localizedName description:localizedDescription contents:contents]);
}

- (instancetype)initWithIdentifier:(OCLicenseProductIdentifier)identifier name:(NSString *)localizedName description:(nullable NSString *)localizedDescription contents:(NSArray<OCLicenseFeatureIdentifier> *)contents
{
	if ((self = [super init]) != nil)
	{
		_identifier = identifier;

		_localizedName = localizedName;
		_localizedDescription = localizedDescription;

		_contents = contents;
	}

	return (self);
}

- (NSArray<OCLicenseEntitlement *> *)entitlements
{
	@synchronized(self)
	{
		if (_entitlements == nil)
		{
			_entitlements = [self.manager _entitlementsForProduct:self];
		}

		return (_entitlements);
	}
}

#pragma mark - Tools
+ (NSString *)stringForType:(OCLicenseType)type
{
	switch (type)
	{
		case OCLicenseTypeNone:
			return (@"none");
		break;

		case OCLicenseTypeTrial:
			return (@"trial");
		break;

		case OCLicenseTypePurchase:
			return (@"purchase");
		break;

		case OCLicenseTypeSubscription:
			return (@"subscription");
		break;
	}

	return (@"unknown");
}

@end
