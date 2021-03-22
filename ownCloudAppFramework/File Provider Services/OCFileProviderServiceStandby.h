//
//  OCFileProviderServiceStandby.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 17.12.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCFileProviderServiceStandby : NSObject

- (instancetype)initWithCore:(OCCore *)core;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
