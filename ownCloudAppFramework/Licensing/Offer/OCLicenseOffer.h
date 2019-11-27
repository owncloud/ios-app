//
//  OCLicenseOffer.h
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
#import "OCLicenseTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class OCLicenseProvider;

typedef void(^OCLicenseOfferCommitHandler)(OCLicenseOfferCommitOptions options);

typedef NS_ENUM(NSUInteger, OCLicenseOfferState)
{
	OCLicenseOfferStateUncommitted,	//!< The offer has not been commited to (bought) by the user.
	OCLicenseOfferStateRedundant,	//!< The user has not committed to (bought) the offer, but committed to (an)other offer(s) that also cover the entirety of the contents of this offer. It is therefore redundant.

	OCLicenseOfferStateInProgress,	//!< The user is committing to (buying) the offer, but the commitment is still being processed.

	OCLicenseOfferStateCommitted	//!< The user has commited to (bought) the offer.
};

@interface OCLicenseOffer : NSObject

+ (instancetype)offerWithIdentifier:(OCLicenseOfferIdentifier)identifier type:(OCLicenseType)type product:(OCLicenseProductIdentifier)productIdentifier;

#pragma mark - Metadata
@property(nullable,strong) OCLicenseOfferIdentifier identifier;
@property(weak) OCLicenseProvider *provider;

#pragma mark - Offer type
@property(assign) OCLicenseType type;
@property(strong) OCLicenseProductIdentifier productIdentifier;

#pragma mark - State
@property(assign) OCLicenseOfferState state;

#pragma mark - Availability
@property(nullable,strong) NSDate *fromDate;
@property(nullable,strong) NSDate *untilDate;
@property(assign,nonatomic) BOOL available;

#pragma mark - Price information
@property(nullable,strong) NSDecimalNumber *price;
@property(nullable,strong) NSLocale *priceLocale;

@property(nonatomic,strong) NSString *localizedPriceTag;

#pragma mark - Request offer / Make purchase
@property(nullable,copy) OCLicenseOfferCommitHandler commitHandler; //!< Used as -commitWithOptions: implementation if provided
- (void)commitWithOptions:(OCLicenseOfferCommitOptions)options; //!< Commits to purchasing the offer, entering a purchase UI flow

@end

extern OCLicenseOfferCommitOption OCLicenseOfferCommitOptionBaseViewController;

NS_ASSUME_NONNULL_END
