//
//  NSDate+RFC3339.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 03.12.19.
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

#import "NSDate+RFC3339.h"

@implementation NSDate (RFC3339)

+ (NSDate *)dateFromRFC3339DateString:(NSString *)dateString
{
	static dispatch_once_t onceToken = 0;
	static NSDateFormatter *rfc3339DateFormatter;
	NSDate *parsedDate = nil;

	dispatch_once(&onceToken, ^{
		NSLocale *posixLocale;

		if ((posixLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]) != nil)
		{
			rfc3339DateFormatter = [[NSDateFormatter alloc] init];
			rfc3339DateFormatter.locale = posixLocale;
			rfc3339DateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
			rfc3339DateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
		}
	});

	if (rfc3339DateFormatter != nil)
	{
		NSRange timezoneDelimiterRange;

		timezoneDelimiterRange = [dateString rangeOfString:@"+"];
		if (timezoneDelimiterRange.location == NSNotFound)
		{
			if ([dateString length] > 10)
			{
				timezoneDelimiterRange = [dateString rangeOfString:@"-" options:0 range:NSMakeRange(10, [dateString length]-10)];
			}
		}

		if (timezoneDelimiterRange.location != NSNotFound)
		{
			dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@"" options:0 range:NSMakeRange(timezoneDelimiterRange.location, [dateString length]-timezoneDelimiterRange.location)];
		}

		parsedDate = [rfc3339DateFormatter dateFromString:dateString];
	}

	return (parsedDate);
}

@end
