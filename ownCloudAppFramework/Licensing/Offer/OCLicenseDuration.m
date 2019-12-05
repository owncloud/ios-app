//
//  OCLicenseDuration.m
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "OCLicenseDuration.h"

@implementation OCLicenseDuration

- (instancetype)initWithUnit:(OCLicenseDurationUnit)unit length:(OCLicenseDurationLength)length
{
	if ((self = [super init]) != nil)
	{
		_unit = unit;
		_length = length;
	}

	return (self);
}

- (NSTimeInterval)duration
{
	switch (_unit)
	{
		case OCLicenseDurationUnitDay:
			return (24 * 3600 * _length);
		break;

		case OCLicenseDurationUnitWeek:
			return (7 * 24 * 3600 * _length);
		break;

		case OCLicenseDurationUnitMonth:
			return (30 * 24 * 3600 * _length);
		break;

		case OCLicenseDurationUnitYear:
			return (365 * 24 * 3600 * _length);
		break;

		case OCLicenseDurationUnitNone:
		break;
	}

	return (0);
}

- (NSString *)localizedDescription
{
	NSString *format = nil;

	switch (_unit)
	{
		case OCLicenseDurationUnitDay:
			if (_length == 1)
			{
				format = OCLocalized(@"%lu day");
			}
			else
			{
				format = OCLocalized(@"%lu days");
			}
		break;

		case OCLicenseDurationUnitWeek:
			if (_length == 1)
			{
				format = OCLocalized(@"%lu week");
			}
			else
			{
				format = OCLocalized(@"%lu weeks");
			}
		break;

		case OCLicenseDurationUnitMonth:
			if (_length == 1)
			{
				format = OCLocalized(@"%lu month");
			}
			else
			{
				format = OCLocalized(@"%lu months");
			}
		break;

		case OCLicenseDurationUnitYear:
			if (_length == 1)
			{
				format = OCLocalized(@"%lu year");
			}
			else
			{
				format = OCLocalized(@"%lu years");
			}
		break;

		case OCLicenseDurationUnitNone:
		break;
	}

	if (format != nil)
	{
		return ([NSString stringWithFormat:format, _length]);
	}

	return (nil);
}

- (NSDate *)dateWithDurationAddedTo:(NSDate *)date
{
	// TODO: Create more sophisticated implementation that computes the _precise_ date, so that 1 Jan + 1 month = 1 Feb, 10 Feb 2019 + 1 year = 10 Feb 2020
	return ([date dateByAddingTimeInterval:self.duration]);
}

@end


@implementation SKProductSubscriptionPeriod (OCLicenseDuration)

- (nullable OCLicenseDuration *)licenseDuration
{
	OCLicenseDurationUnit unit = OCLicenseDurationUnitNone;

	switch (self.unit)
	{
		case SKProductPeriodUnitDay:
			unit = OCLicenseDurationUnitDay;
		break;

		case SKProductPeriodUnitWeek:
			unit = OCLicenseDurationUnitWeek;
		break;

		case SKProductPeriodUnitMonth:
			unit = OCLicenseDurationUnitMonth;
		break;

		case SKProductPeriodUnitYear:
			unit = OCLicenseDurationUnitYear;
		break;
	}

	if (unit !=  OCLicenseDurationUnitNone)
	{
		return ([[OCLicenseDuration alloc] initWithUnit:unit length:self.numberOfUnits]);
	}

	return (nil);
}

@end
