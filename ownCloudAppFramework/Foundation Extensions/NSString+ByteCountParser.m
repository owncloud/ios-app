//
//  NSString+ByteCountParser.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 30.03.21.
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

#import "NSString+ByteCountParser.h"

@implementation NSString (ByteCountParser)

- (nullable NSNumber *)byteCountNumber
{
	NSNumber *byteCountNumber = nil;
	NSString *lcString = self.lowercaseString, *bcString = nil;
	NSUInteger multiplier = 0;

	if ([lcString hasSuffix:@"tb"])
	{
		bcString = [lcString substringToIndex:self.length-2];
		multiplier = 1000000000000;
	}
	else if ([lcString hasSuffix:@"tib"])
	{
		bcString = [lcString substringToIndex:self.length-3];
		multiplier = 1099511627776;
	}
	else if ([lcString hasSuffix:@"gb"])
	{
		bcString = [lcString substringToIndex:self.length-2];
		multiplier = 1000000000;
	}
	else if ([lcString hasSuffix:@"gib"])
	{
		bcString = [lcString substringToIndex:self.length-3];
		multiplier = 1073741824;
	}
	else if ([lcString hasSuffix:@"mb"])
	{
		bcString = [lcString substringToIndex:self.length-2];
		multiplier = 1000000;
	}
	else if ([lcString hasSuffix:@"mib"])
	{
		bcString = [lcString substringToIndex:self.length-3];
		multiplier = 1048576;
	}
	else if ([lcString hasSuffix:@"kb"])
	{
		bcString = [lcString substringToIndex:self.length-2];
		multiplier = 1000;
	}
	else if ([lcString hasSuffix:@"kib"])
	{
		bcString = [lcString substringToIndex:self.length-3];
		multiplier = 1024;
	}
	else if ([lcString hasSuffix:@"b"])
	{
		bcString = [lcString substringToIndex:self.length-1];
		multiplier = 1;
	}
	else if (lcString.length > 0)
	{
		bcString = lcString;
		multiplier = 1;
	}

	if (multiplier != 0)
	{
		byteCountNumber = @(((NSUInteger)bcString.integerValue) * multiplier);
	}

	return (byteCountNumber);
}

@end
