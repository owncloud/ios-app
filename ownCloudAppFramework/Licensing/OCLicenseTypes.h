//
//  OCLicenseTypes.h
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

#import <Foundation/Foundation.h>

typedef NSString* OCLicenseProductIdentifier NS_TYPED_ENUM;
typedef NSString* OCLicenseFeatureIdentifier NS_TYPED_ENUM;
typedef NSString* OCLicenseProviderIdentifier NS_TYPED_ENUM;
typedef NSString* OCLicenseEnvironmentIdentifier;
typedef NSString* OCLicenseEntitlementIdentifier;
typedef NSString* OCLicenseOfferIdentifier;
typedef NSString* OCLicenseOfferGroupIdentifier;

typedef NSString* OCLicenseOfferCommitOption NS_TYPED_ENUM;
typedef NSDictionary<OCLicenseOfferCommitOption,id>* OCLicenseOfferCommitOptions;

typedef NSString* OCLicenseEntitlementEnvironmentApplicableRule;

typedef NS_ENUM(NSUInteger, OCLicenseType)
{
	OCLicenseTypeNone,		//!< NO license
	OCLicenseTypeTrial,		//!< Trial
	OCLicenseTypeSubscription,	//!< Subscription
	OCLicenseTypePurchase		//!< Regular purchase
};

typedef NS_ENUM(NSUInteger, OCLicenseAuthorizationStatus)
{
	OCLicenseAuthorizationStatusUnknown,		//!< Status unknown
	OCLicenseAuthorizationStatusDenied,		//!< Authorization denied
	OCLicenseAuthorizationStatusExpired,		//!< Authorization expired, existed at some point in the past
	OCLicenseAuthorizationStatusGranted		//!< Authorization granted
};

@class OCLicenseEnvironment;
@class OCLicenseObserver;
@class OCLicenseOffer;

NS_ASSUME_NONNULL_BEGIN

typedef void(^OCLicenseObserverAuthorizationStatusUpdateHandler)(OCLicenseObserver * _Nonnull observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus);
typedef void(^OCLicenseObserverOffersUpdateHandler)(OCLicenseObserver * _Nonnull observer, BOOL isInitial, NSArray<OCLicenseOffer *> *offers);

NS_ASSUME_NONNULL_END
