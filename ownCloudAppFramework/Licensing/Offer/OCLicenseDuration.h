//
//  OCLicenseDuration.h
//  ownCloud
//
//  Created by Felix Schwarz on 04.12.19.
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
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSUInteger, OCLicenseDurationUnit)
{
	OCLicenseDurationUnitNone,

	OCLicenseDurationUnitDay,
	OCLicenseDurationUnitWeek,
	OCLicenseDurationUnitMonth,
	OCLicenseDurationUnitYear
};

typedef NSInteger OCLicenseDurationLength;

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseDuration : NSObject

@property(assign) OCLicenseDurationLength length;
@property(assign) OCLicenseDurationUnit unit;

@property(nonatomic,readonly) NSTimeInterval duration;
@property(nonatomic,readonly) NSString *localizedDescription;
@property(nonatomic,readonly) NSString *localizedDescriptionSingular;

- (instancetype)initWithUnit:(OCLicenseDurationUnit)unit length:(OCLicenseDurationLength)length;

- (NSDate *)dateWithDurationAddedTo:(NSDate *)date;

@end

@interface SKProductSubscriptionPeriod (OCLicenseDuration)

@property(readonly,nonatomic,nullable) OCLicenseDuration *licenseDuration;

@end

NS_ASSUME_NONNULL_END
