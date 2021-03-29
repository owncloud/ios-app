//
//  NSDate+ComputedTimes.m
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

#import "NSDate+ComputedTimes.h"

@implementation NSDate (ComputedTimes)

- (instancetype)recomputeWithUnits:(NSCalendarUnit)units modifier:(void(^)(NSDateComponents *components))componentModifier
{
	NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
	NSDateComponents *components = [calendar components:units fromDate:self];

	if (componentModifier != nil)
	{
		componentModifier(components);
	}

	return ([calendar dateFromComponents:components]);
}

+ (instancetype)startOfRelativeDay:(NSInteger)dayOffset
{
	return ([[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)(dayOffset * 24 * 60 * 60)] recomputeWithUnits:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear modifier:nil]);
}

+ (instancetype)startOfRelativeWeek:(NSInteger)weekOffset
{
	return ([[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)(weekOffset * 7 * 24 * 60 * 60)] recomputeWithUnits:NSCalendarUnitWeekday|NSCalendarUnitWeekOfMonth|NSCalendarUnitMonth|NSCalendarUnitYear modifier:^(NSDateComponents *components) {
		components.weekday = 2; // Monday, 1 = Sunday
	}]);
}

+ (instancetype)startOfRelativeMonth:(NSInteger)monthOffset
{
	return ([NSDate.date recomputeWithUnits:NSCalendarUnitMonth|NSCalendarUnitYear modifier:^(NSDateComponents *components) {
		if (monthOffset < 0)
		{
			NSInteger remainingMonths = -monthOffset;

			while (remainingMonths > 0)
			{
				if (components.month > 1)
				{
					components.month -= 1;
				}
				else
				{
					components.year -= 1;
					components.month = 12;
				}

				remainingMonths--;
			};
		}
		else
		{
			NSInteger remainingMonths = monthOffset;

			while (remainingMonths > 0)
			{
				if (components.month > 11)
				{
					components.year += 1;
					components.month = 1;
				}
				else
				{
					components.month += 1;
				}

				remainingMonths--;
			};
		}
	}]);
}

+ (instancetype)startOfRelativeYear:(NSInteger)yearOffset
{
	return ([NSDate.date recomputeWithUnits:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear modifier:^(NSDateComponents *components) {
		components.day = 1;
		components.month = 1;
		components.year += yearOffset;
	}]);
}

+ (nullable instancetype)dateFromKeywordString:(NSString *)dateString
{
	NSArray<NSString *> *components = [dateString componentsSeparatedByString:@"-"];
	NSString *yearString  = ((components.firstObject != nil) && (components.firstObject.length == 4)) ? components.firstObject : nil;
	NSString *monthString = ((components.count >= 2) && (components[1].length > 0)) ? components[1] : nil;
	NSString *dayString   = ((components.count == 3) && (components[2].length > 0)) ? components[2] : nil;

	if (yearString != nil)
	{
		if (components.count == 1)
		{
			return ([NSDate.date recomputeWithUnits:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear modifier:^(NSDateComponents *components) {
				components.year = yearString.integerValue;
				components.month = 1;
				components.day = 1;
			}]);
		}
		else if ((components.count == 2) && (monthString != nil))
		{
			return ([NSDate.date recomputeWithUnits:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear modifier:^(NSDateComponents *components) {
				components.year = yearString.integerValue;
				components.month = monthString.integerValue;
				components.day = 1;
			}]);
		}
		else if ((components.count == 3) && (monthString != nil) && (dayString != nil))
		{
			return ([NSDate.date recomputeWithUnits:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear modifier:^(NSDateComponents *components) {
				components.year = yearString.integerValue;
				components.month = monthString.integerValue;
				components.day = dayString.integerValue;
			}]);
		}
	}

	return (nil);
}


@end
