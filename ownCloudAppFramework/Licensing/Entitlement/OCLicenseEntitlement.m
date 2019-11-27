//
//  OCLicenseEntitlement.m
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

#import "OCLicenseEntitlement.h"

@implementation OCLicenseEntitlement

+ (instancetype)entitlementWithIdentifier:(nullable OCLicenseEntitlementIdentifier)identifier forProduct:(OCLicenseProductIdentifier)productIdentifier type:(OCLicenseType)type valid:(BOOL)valid expiryDate:(nullable NSDate *)expiryDate applicability:(nullable OCLicenseEntitlementEnvironmentApplicableRule)applicability
{
	OCLicenseEntitlement *entitlement = [self new];

	entitlement.identifier = identifier;
	entitlement.productIdentifier = productIdentifier;
	entitlement.valid = valid;
	entitlement.expiryDate = expiryDate;
	entitlement.environmentApplicableRule = applicability;

	return (entitlement);
}

- (BOOL)valid
{
	// Check expiry date
	if (_valid && (self.expiryDate != nil) && ([self.expiryDate timeIntervalSinceNow] < 0))
	{
		// Entitlement has expired => no longer valid
		return (NO);
	}

	// Return the value for .valid that's been set
	return (_valid);
}

- (BOOL)isApplicableInEnvironment:(OCLicenseEnvironment *)environment
{
	if (self.environmentApplicableRule != nil)
	{
		if (environment == nil)
		{
			// Not applicable to any environment if there's an environment applicability rule but no environment to check against
			return (NO);
		}
		else
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:self.environmentApplicableRule, nil];

			return ([predicate evaluateWithObject:environment]);
		}
	}

	return (YES);
}

- (NSDate *)nextStatusChangeDate
{
	if (_nextStatusChangeDate != nil)
	{
		return (_nextStatusChangeDate);
	}

	return (self.expiryDate);
}

- (OCLicenseAuthorizationStatus)authorizationStatusInEnvironment:(OCLicenseEnvironment *)environment
{
	// Check expiry date
	if ((self.expiryDate != nil) && ([self.expiryDate timeIntervalSinceNow] < 0))
	{
		// Entitlement has an expiry date that's in the past => expired
		return (OCLicenseAuthorizationStatusExpired);
	}

	// Check validity
	if (self.valid)
	{
		// Check applicability
		if ([self isApplicableInEnvironment:environment])
		{
			// Entitlement is valid and applicable to environment => granted
			return (OCLicenseAuthorizationStatusGranted);
		}
	}

	// No valid, non-expired and applicable
	return (OCLicenseAuthorizationStatusDenied);
}

@end
