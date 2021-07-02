//
//  NSDate+ComputedTimes.h
//  ownCloud
//
//  Created by Felix Schwarz on 19.03.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2021, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (ComputedTimes)

+ (instancetype)startOfRelativeDay:(NSInteger)dayOffset;
+ (instancetype)startOfRelativeWeek:(NSInteger)weekOffset;
+ (instancetype)startOfRelativeMonth:(NSInteger)monthOffset;
+ (instancetype)startOfRelativeYear:(NSInteger)yearOffset;

+ (nullable instancetype)dateFromKeywordString:(NSString *)dateString;

@end

NS_ASSUME_NONNULL_END
