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

@implementation OCBookmark (AppExtensions)

- (NSString *)displayName
{
	return ((NSString *)self.userInfo[OCBookmarkUserInfoKeyDisplayName]);
}

- (void)setDisplayName:(NSString *)displayName
{
	self.userInfo[OCBookmarkUserInfoKeyDisplayName] = displayName;
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
		NSString *displayName = nil, *userName = nil;

		if ((displayName = self.displayName) != nil)
		{
			userNamePrefix = [displayName stringByAppendingString:@"@"];
		}

		if ((userNamePrefix.length == 0) && ((userName = self.userName) != nil))
		{
			userNamePrefix = [userName stringByAppendingString:@"@"];
		}

		if (self.originURL.host != nil)
		{
			return ([userNamePrefix stringByAppendingString:self.originURL.host]);
		}
		else
		{
			return ([userNamePrefix stringByAppendingString:self.url.host]);
		}
	}
}

@end

OCBookmarkUserInfoKey OCBookmarkUserInfoKeyDisplayName = @"OCBookmarkDisplayName";
