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

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

#import "NotificationMessagePresenter.h"
#import "OCBookmark+AppExtensions.h"

@implementation NotificationMessagePresenter

- (instancetype)initForBookmarkUUID:(OCBookmarkUUID)bookmarkUUID
{
	if ((self = [super init]) != nil)
	{
		self.identifier = [@"localNotification" stringByAppendingFormat:@".%@", bookmarkUUID.UUIDString];
		_bookmarkUUID = bookmarkUUID;
	}

	return (self);
}

- (OCMessagePresentationPriority)presentationPriorityFor:(OCMessage *)message
{
	if ((message.localizedTitle != nil) && (message.choices != nil) && [message.bookmarkUUID isEqual:_bookmarkUUID])
	{
		return (OCMessagePresentationPriorityDefault);
	}

	return (OCMessagePresentationPriorityWontPresent);
}

- (void)present:(OCMessage *)message completionHandler:(void (^)(OCMessagePresentationResult, OCMessageChoice * _Nullable))completionHandler
{
	UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;

	[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
		if (granted)
		{
			UNMutableNotificationContent *content = [UNMutableNotificationContent new];

			if (message.categoryIdentifier != nil)
			{
				content.categoryIdentifier = message.categoryIdentifier;
			}

			OCBookmark *bookmark;

			if ((OCBookmarkManager.sharedBookmarkManager.bookmarks.count > 1) &&
			    (((bookmark = [OCBookmarkManager.sharedBookmarkManager bookmarkForUUID:message.bookmarkUUID]) != nil) &&
			     (bookmark.shortName != nil))
			   )
			{
				content.title = bookmark.shortName;
				content.subtitle = message.localizedTitle;
			}
			else
			{
				content.title = message.localizedTitle;
			}

			if (message.localizedDescription != nil)
			{
				content.body = message.localizedDescription;
			}

			UNNotificationRequest *request;

			request = [UNNotificationRequest requestWithIdentifier:ComposeNotificationIdentifier(NotificationMessagePresenter, message.uuid.UUIDString) content:content trigger:nil];

			[NotificationManager.sharedNotificationManager addNotificationRequest:request withCompletionHandler:^(NSError * _Nonnull error) {
				OCLogDebug(@"Notification error: %@", error);

				completionHandler(((error == nil) ? (OCMessagePresentationResultDidPresent|OCMessagePresentationResultRequiresEndNotification) : OCMessagePresentationResultDidNotPresent), nil);
			}];
		}
	}];
}

- (void)endPresentationOfMessage:(OCMessage *)message
{
	NSString *notificationIdentifier;

	if ((notificationIdentifier = ComposeNotificationIdentifier(NotificationMessagePresenter, message.uuid.UUIDString)) != nil)
	{
		[UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:@[ notificationIdentifier ]];
		[UNUserNotificationCenter.currentNotificationCenter removeDeliveredNotificationsWithIdentifiers:@[ notificationIdentifier ]];
	}
}

+ (void)handleNotificationCenter:(nonnull UNUserNotificationCenter *)center response:(nonnull UNNotificationResponse *)response identifier:(nonnull NSString *)identifier completionHandler:(nonnull dispatch_block_t)completionHandler
{
	OCMessageUUID messageUUID;

	if ((messageUUID = [[NSUUID alloc] initWithUUIDString:identifier]) != nil)
	{
		OCMessage *message;

		if ((message = [OCMessageQueue.globalQueue messageWithUUID:messageUUID]) != nil)
		{
			if ([response.actionIdentifier isEqual:UNNotificationDefaultActionIdentifier])
			{
				// User tapped notification
				OCLogDebug(@"User tapped notification %@", message);
				[NSNotificationCenter.defaultCenter postNotificationName:NotificationMessagePresenterShowMessageNotification object:message];
			}
			else if ([response.actionIdentifier isEqual:UNNotificationDismissActionIdentifier])
			{
				// User dismissed notification
				OCLogDebug(@"User dismissed notification %@", message);
			}
			else
			{
				// User made a choice
				for (OCMessageChoice *choice in message.choices)
				{
					if ([choice.identifier isEqual:response.actionIdentifier])
					{
						[OCMessageQueue.globalQueue resolveMessage:message withChoice:choice];
					}
				}
			}
		}
	}

	completionHandler();
}

@end

NSNotificationName NotificationMessagePresenterShowMessageNotification = @"NotificationMessagePresenterShowMessage";
