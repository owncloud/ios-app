//
//  OCLicenseTrialProvider.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 22.11.19.
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
#import "OCLicenseTrialProvider.h"
#import "OCLicenseOffer.h"

@implementation OCLicenseTrialProvider

+ (instancetype)trialProviderWithIdentifier:(OCLicenseProviderIdentifier)identifier forProductIdentifiers:(NSArray<OCLicenseProductIdentifier> *)productIdentifiers withDuration:(NSTimeInterval)trialDuration
{
	OCLicenseTrialProvider *trialProvider = [OCLicenseTrialProvider new];

	trialProvider.identifier = identifier;
	trialProvider.productIdentifiers = productIdentifiers;
	trialProvider.trialDuration = trialDuration;

	return (trialProvider);
}

- (void)startProvidingWithCompletionHandler:(OCLicenseProviderCompletionHandler)completionHandler
{
	NSMutableArray<OCLicenseOffer *> *offers = [NSMutableArray new];

	for (OCLicenseProductIdentifier productIdentifier in _productIdentifiers)
	{
		OCLicenseProduct *product;

		if ((product = [self.manager productWithIdentifier:productIdentifier]) != nil)
		{
			OCLicenseOffer *offer = [OCLicenseOffer new];
		}
	}
}

@end
