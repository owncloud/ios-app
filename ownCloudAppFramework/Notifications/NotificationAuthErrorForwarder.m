//
//  NotificationAuthErrorForwarder.m
//  ownCloud
//
//  Created by Felix Schwarz on 30.09.20.
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

#import "NotificationAuthErrorForwarder.h"

@implementation NotificationAuthErrorForwarder

+ (void)handleNotificationCenter:(nonnull UNUserNotificationCenter *)center response:(nonnull UNNotificationResponse *)response identifier:(nonnull NSString *)identifier completionHandler:(nonnull dispatch_block_t)completionHandler
{
	if ([response.actionIdentifier isEqual:UNNotificationDefaultActionIdentifier])
	{
		OCBookmarkUUID bookmarkUUID = [[NSUUID alloc] initWithUUIDString:identifier];

		[NSNotificationCenter.defaultCenter postNotificationName:NotificationAuthErrorForwarderOpenAccount object:bookmarkUUID];
	}

	completionHandler();
}

@end

NSNotificationName NotificationAuthErrorForwarderOpenAccount = @"NotificationAuthErrorForwarderOpenAccount";
