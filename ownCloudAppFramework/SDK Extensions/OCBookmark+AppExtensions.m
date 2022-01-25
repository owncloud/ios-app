//
//  OCBookmark+AppExtensions.m
//  ownCloud
//
//  Created by Felix Schwarz on 08.07.20.
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

#import "OCBookmark+AppExtensions.h"

static OCBookmarkUserInfoKey OCBookmarkUserInfoKeyDisplayName = @"OCBookmarkDisplayName";

@implementation OCBookmark (AppExtensions)

- (NSString *)displayName
{
	if (self.userDisplayName != nil)
	{
		return (self.userDisplayName);
	}

	return ((NSString *)self.userInfo[OCBookmarkUserInfoKeyDisplayName]);
}

- (NSString *)shortName
{
	if (self.name != nil)
	{
		return (self.name);
	}
	else
	{
		NSString *userNamePrefix = @"";
		NSString *userDisplayName = nil, *userName = nil;

		if (((userDisplayName = self.userDisplayName) != nil) && (userDisplayName.length > 0))
		{
			userNamePrefix = [userDisplayName stringByAppendingString:@"@"];
		}
		else if (((userDisplayName = self.displayName) != nil) && (userDisplayName.length > 0))
		{
			userNamePrefix = [userDisplayName stringByAppendingString:@"@"];
		}

		if ((userNamePrefix.length == 0) && ((userName = self.userName) != nil) && (userName.length > 0))
		{
			userNamePrefix = [userName stringByAppendingString:@"@"];
		}

		if (self.url.host != nil)
		{
			return ([userNamePrefix stringByAppendingString:self.url.host]);
		}
		else if (self.url.host != nil)
		{
			return (userNamePrefix);
		}
		else
		{
			return (userNamePrefix);
		}
	}
}

@end
