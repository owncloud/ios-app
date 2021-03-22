//
//  OCLicenseFeature.m
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

#import "OCLicenseFeature.h"
#import "OCLicenseProduct.h"

@implementation OCLicenseFeature

+ (instancetype)featureWithIdentifier:(OCLicenseFeatureIdentifier)identifier
{
	return ([[self alloc] initWithIdentifier:identifier name:nil description:nil]);
}

+ (instancetype)featureWithIdentifier:(OCLicenseFeatureIdentifier)identifier name:(NSString *)localizedName description:(NSString *)localizedDescription
{
	return ([[self alloc] initWithIdentifier:identifier name:localizedName description:localizedDescription]);
}

- (instancetype)initWithIdentifier:(OCLicenseFeatureIdentifier)identifier name:(NSString *)localizedName description:(NSString *)localizedDescription
{
	if ((self = [super init]) != nil)
	{
		_identifier = identifier;
		_localizedName = localizedName;
		_localizedDescription = localizedDescription;
	}

	return (self);
}

- (NSArray<OCLicenseEntitlement *> *)entitlements
{
	@synchronized(self)
	{
		if (_entitlements == nil)
		{
			NSMutableArray<OCLicenseEntitlement *> *entitlements = [NSMutableArray new];

			for (OCLicenseProduct *product in self.containedInProducts)
			{
				if (product.entitlements != nil)
				{
					[entitlements addObjectsFromArray:product.entitlements];
				}
			}

			if (entitlements.count > 0)
			{
				_entitlements = entitlements;
			}
		}

		return (_entitlements);
	}
}

@end
