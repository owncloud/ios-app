//
//  NotificationManager.m
//  ownCloud
//
//  Created by Felix Schwarz on 26.03.20.
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "NotificationManager.h"

@implementation NotificationManager

+ (void)load
{
	if (NotificationManager.sharedNotificationManager == nil)
	{
		// Ensure registration as delegate
		OCLogError(@"Error initializing NotificationManager");
	}
}

#pragma mark - Init & Dealloc
+ (instancetype)sharedNotificationManager
{
	static dispatch_once_t onceToken;
	static NotificationManager *sharedNotificationManager;

	dispatch_once(&onceToken, ^{
		sharedNotificationManager = [self new];
	});

	return (sharedNotificationManager);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		[UNUserNotificationCenter.currentNotificationCenter setDelegate:self];
	}

	return (self);
}

- (void)dealloc
{
	[UNUserNotificationCenter.currentNotificationCenter setDelegate:nil];
}

#pragma mark - Notification methods
- (void)addNotificationRequest:(UNNotificationRequest *)notificationRequest withCompletionHandler:(void (^)(NSError *error))completionHandler;
{
	[UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:notificationRequest withCompletionHandler:completionHandler];
}

#pragma mark - Delegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
	completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);
}

@end
