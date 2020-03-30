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

#pragma mark - Category registration
- (void)registerCategories
{
	NSMutableSet<UNNotificationCategory *> *categories = [NSMutableSet new];

	for (OCSyncIssueTemplate *template in OCSyncIssueTemplate.templates)
	{
		NSMutableArray<UNNotificationAction *> *actions = [NSMutableArray new];
		UNNotificationCategory *category = nil;

		for (OCSyncIssueChoice *choice in template.choices)
		{
			UNNotificationAction *action;

			if ((action = [UNNotificationAction actionWithIdentifier:choice.identifier
									   title:choice.label
									 options:((choice.type == OCIssueChoiceTypeDestructive) ? UNNotificationActionOptionDestructive : UNNotificationActionOptionNone)]) != nil)
			{
				[actions addObject:action];
			}
		}

		if ((category = [UNNotificationCategory categoryWithIdentifier:template.identifier actions:actions intentIdentifiers:@[] options:UNNotificationCategoryOptionHiddenPreviewsShowTitle|UNNotificationCategoryOptionHiddenPreviewsShowSubtitle]) != nil)
		{
			[categories addObject:category];
		}
	}

	[UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:categories];
}

#pragma mark - Notification methods
- (void)addNotificationRequest:(UNNotificationRequest *)notificationRequest withCompletionHandler:(void (^)(NSError *error))completionHandler
{
	[UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:notificationRequest withCompletionHandler:completionHandler];
}

#pragma mark - Delegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
	completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
	NSString *composedIdentifier = response.notification.request.identifier;
	NSArray<NSString *> *components;

	if (((components = [composedIdentifier componentsSeparatedByString:@":"]) != nil) && (components.count >= 2))
	{
		NSString *handlerClassName = [components firstObject];
		NSString *notificationIdentifier = [[components subarrayWithRange:NSMakeRange(1, components.count-1)] componentsJoinedByString:@":"];

		Class<NotificationResponseHandler> handlerClass = NSClassFromString(handlerClassName);

		if ([handlerClass conformsToProtocol:@protocol(NotificationResponseHandler)])
		{
			[handlerClass handleNotificationCenter:center response:response identifier:notificationIdentifier completionHandler:completionHandler];
			return;
		}
	}

	OCLogError(@"Could not route notification response %@", response);
	completionHandler();
}

@end
