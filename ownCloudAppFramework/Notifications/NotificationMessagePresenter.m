//
//  NotificationMessagePresenter.m
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

#import "NotificationMessagePresenter.h"
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "NotificationManager.h"

@implementation NotificationMessagePresenter

- (instancetype)initForBookmarkUUID:(OCBookmarkUUID)bookmarkUUID
{
	if ((self = [super init]) != nil)
	{
		self.identifier = @"localNotification";
		_bookmarkUUID = bookmarkUUID;
	}

	return (self);
}

- (OCMessagePresentationPriority)presentationPriorityFor:(OCMessage *)message
{
	if (message.syncIssue != nil)
	{
		if ([message.bookmarkUUID isEqual:_bookmarkUUID])
		{
			return (OCMessagePresentationPriorityDefault);
		}
	}

	return (OCMessagePresentationPriorityWontPresent);
}

- (void)present:(OCMessage *)message completionHandler:(void (^)(BOOL, OCSyncIssueChoice * _Nullable))completionHandler
{
	UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

	[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
		if (granted)
		{
			UNMutableNotificationContent *content = [UNMutableNotificationContent new];

			content.title = message.syncIssue.localizedTitle;
			content.body = message.syncIssue.localizedDescription;

			UNNotificationRequest *request;

			request = [UNNotificationRequest requestWithIdentifier:message.uuid.UUIDString content:content trigger:nil];

			[NotificationManager.sharedNotificationManager addNotificationRequest:request withCompletionHandler:^(NSError * _Nonnull error) {
				OCLogDebug(@"Notification error: %@", error);

				completionHandler((error == nil), nil);
			}];
		}
	}];
}

@end
