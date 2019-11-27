//
//  OCLicenseObserver.h
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

@interface OCLicenseObserver : NSObject

@property(weak,nullable) OCLicenseEnvironment *environment; //!< The environment for which to observe authorization status
@property(weak,nullable) id owner; //!< The owner of the observer. If the owner is deallocated, the observer is automatically removed.

@property(strong,nullable) NSArray<OCLicenseProductIdentifier> *products; //!< Identifiers of the products to observe (need to be resolvable - or authorizationStatus will always be denied)
@property(strong,nullable) NSArray<OCLicenseFeatureIdentifier> *features; //!< Identifiers of the features to observe (need to be resolvable - or authorizationStatus will always be denied)

@property(assign,nonatomic) OCLicenseAuthorizationStatus authorizationStatus; //!< Combined authorization status of all .products and .features (== lowest authorization status determined among them).
@property(copy,nullable) OCLicenseObserverAuthorizationStatusUpdateHandler statusUpdateHandler; //!< Update handler block. Called whenever the authorizationStatus changes.

@property(strong,nonatomic,nullable) NSArray<OCLicenseOffer *> *offers; //!< Offers covering any of the products or features specified
@property(copy,nullable) OCLicenseObserverOffersUpdateHandler offersUpdateHandler; //!< Update handler block. Called whenever the offers change.

@end

NS_ASSUME_NONNULL_END
