//
//  AppLock.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 24.06.19.
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

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

#import "AppLockMethod.h"
#import "NSError+AppLock.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppLock : NSObject

#pragma mark - Shared instance
@property(class,readonly,nonatomic,strong) AppLock *sharedAppLock;

#pragma mark - Status
@property(readonly,nonatomic) BOOL unlocked; //!< Indicates whether the AppLock is currently unlocked
@property(readonly,strong,nullable) NSDate *lastUnlockDate; //!< Time at which the app lock was last unlocked. nil if app lock is (re-)locked.
@property(readonly,strong,nullable) NSDate *lastLockEventDate; //!< Time at which the last lock event was registered (f.ex. unlocking, entering or leaving the app/extension) - used to determine timeout if no valid process sessions were found

@property(readonly,nonatomic,strong,nullable) NSDate *nextPossibleUnlockDate; //!< Indicates the next possible date at which an unlock of the AppLock can be attempted. nil when unlocked.

#pragma mark - Settings
@property(assign,nonatomic) BOOL enabled; //!< Indicates whether the AppLock is enabled.
@property(assign,nonatomic) NSTimeInterval lockTimeout; //!< Indicates the amount of time since [last lock event and last valid session being removed] after which an unlocked AppLock is re-locked

@property(readonly,nonatomic) NSUInteger remainingUnlockAttempts; //!< Indicates the remaining number of times an unlock can be attempted before time penalties kick in.
@property(readonly) NSUInteger maximumUnlockAttempts; //!< Indicates the total number of times an unlock can be attempted before time penalties kick in.

@property(assign,nonatomic) BOOL participateInLockTimeout; //!< Controls whether the current process takes part in determining the lock timeout. Defaults to YES. Should be NO for UI-less code running in the background (like File Extensions).

#pragma mark - Methods
@property(readonly,nonatomic,strong) NSArray<AppLockMethod *> *methods;

- (void)addMethod:(AppLockMethod *)method;
- (void)removeMethod:(AppLockMethod *)method;
- (nullable AppLockMethod *)methodForIdentifier:(AppLockMethodIdentifier)appLockMethodIdentifier;

#pragma mark - Attempt unlock
- (void)attemptUnlockByMethod:(AppLockMethod *)method withSuccess:(BOOL)success completionHandler:(void(^)(NSError * _Nullable error))completionHandler; //!< Method by which AppLockMethods can signal the AppLock the outcome of an unlock attempt.

#pragma mark - Timeout
- (void)enterLockTimeout; //!< Starts the lock timeout period (f.ex. when the app goes into background - or the process that last left the lock timeout appears to be no longer responding)
- (void)leaveLockTimeout; //!< Stops the lock timeout period (f.ex. when the app goes into foreground)

@end

NS_ASSUME_NONNULL_END
