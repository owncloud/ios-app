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

@property(weak,nullable) OCLicenseEnvironment *environment;
@property(weak,nullable) id owner;

@property(strong,nullable) NSArray<OCLicenseProductIdentifier> *products;
@property(strong,nullable) NSArray<OCLicenseFeatureIdentifier> *features;

@property(assign,nonatomic) OCLicenseAuthorizationStatus authorizationStatus;
@property(copy,nullable) OCLicenseObserverUpdateHandler updateHandler;

@end

NS_ASSUME_NONNULL_END
