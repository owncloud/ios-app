//
//  NotificationManager.h
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

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface NotificationManager : NSObject <UNUserNotificationCenterDelegate>

@property(nonatomic,readonly,class,strong) NotificationManager *sharedNotificationManager;

- (void)registerCategories;

- (void)addNotificationRequest:(UNNotificationRequest *)notificationRequest withCompletionHandler:(void (^)(NSError *error))completionHandler;

@end

#define ComposeNotificationIdentifier(aClass,identifier) [NSStringFromClass(aClass.class) stringByAppendingFormat:@":%@", identifier]

@protocol NotificationResponseHandler <NSObject>
+ (void)handleNotificationCenter:(UNUserNotificationCenter *)center response:(UNNotificationResponse *)response identifier:(NSString *)identifier completionHandler:(dispatch_block_t)completionHandler;
@end

NS_ASSUME_NONNULL_END
