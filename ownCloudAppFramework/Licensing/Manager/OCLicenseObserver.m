//
//  OCLicenseObserver.m
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

#import "OCLicenseObserver.h"

@interface OCLicenseObserver ()
{
	BOOL _didInitialUpdate;
}
@end

@implementation OCLicenseObserver

- (void)setAuthorizationStatus:(OCLicenseAuthorizationStatus)authorizationStatus
{
	BOOL isInitial = NO;
	OCLicenseObserverAuthorizationStatusUpdateHandler updateHandler = nil;

	@synchronized(self)
	{
		if (_authorizationStatus != authorizationStatus)
		{
			_authorizationStatus = authorizationStatus;

			if ((updateHandler = self.statusUpdateHandler) != nil)
			{
				if (!_didInitialUpdate)
				{
					isInitial = YES;
					_didInitialUpdate = YES;
				}
			}
		}
	}

	if (updateHandler != nil)
	{
		updateHandler(self, isInitial, authorizationStatus);
	}
}

- (void)setOffers:(NSArray<OCLicenseOffer *> *)offers
{
	BOOL isInitial = NO;
	OCLicenseObserverOffersUpdateHandler updateHandler = nil;

	@synchronized(self)
	{
		if (![_offers isEqual:offers])
		{
			_offers = offers;

			if ((updateHandler = self.offersUpdateHandler) != nil)
			{
				if (!_didInitialUpdate)
				{
					isInitial = YES;
					_didInitialUpdate = YES;
				}
			}
		}
	}

	if (updateHandler != nil)
	{
		updateHandler(self, isInitial, offers);
	}
}

@end
