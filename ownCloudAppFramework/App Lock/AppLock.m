//
//  AppLock.m
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

/*
# Notes
- shared AppLock that manages the locking of the app across extensions (File Provider, File Provider UI, ..) and the app itself

- iPad multitasking adds further complexity. Consider f.ex. this situation:
	- Files app and ownCloud App side by side
	- AppLock is locked
	- File Provider UI (FPUI) is used to unlock AppLock
		- FPUI unlocks AppLock, enters lock timeout when dismissed
		- App itself remains on screen and leaves the lock timeout
		=> depending on order, final state could differ IF the AppLock-using processes aren't managed on their own

- Structure taking multi-process into account:
	- global lastUnlockTime
	- global lastLockEventDate when last lock-related event was registered
	- array of process (unlock) sessions, created when unlocked:
		- OCProcessSession to track process state

- Mechanics
	- when unlocked, sets lastUnlockTime and sends IP notification
		- other running processes pick up IP notification and add their per-process unlock sessions
	- processes that go to the foreground or are launched
		- determine current unlock state. If unlocked:
			- add or update their process' unlock session
			- update lastLockEventDate to current date
	- processes that go to background or are quit
		- remove their process' unlock session
		- determine current unlock state. If unlocked:
			- update lastLockEventDate to current date

	- to determine unlock state, AppLock follows this logic:
		- start with status=locked
		- determine if lockTimeout has passed since lastUnlockTime
			- if false:
				- set status=unlocked
				- return
			- if true:
				- determine if lockTimeout has passed since enterLockTimeoutDate
					- if false:
						- set status=unlocked
						- return
					- if true:
						- iterate over unlock sessions
							- check if OCProcessSession is valid
								- if true:
									- set status=unlocked
*/

#import "AppLock.h"

static OCIPCNotificationName AppLockStateChangedNotification = @"com.owncloud.app-lock.state-changed";

static NSString *AppLockKeychainAccountName = @"app-lock";

static NSString *AppLockLastEnabledKey = @"app-lock.enabled";

static NSString *AppLockLastUnlockDateKey = @"app-lock.last-unlock-date";
static NSString *AppLockLastLockEventDateKey = @"app-lock.last-lock-event-date";
static NSString *AppLockLastUnlockSessionsKey = @"app-lock.unlock-sessions";

static NSString *AppLockFailedUnlockAttemptsKey = @"app-lock.failed-unlock-attempts";

@interface AppLock ()
{
	NSMutableArray <AppLockMethod *> *_methods;

	BOOL _unlocked;

	NSDate *_lastUnlockAttempt;
	NSDate *_nextPossibleUnlockDate;

	BOOL _participateInLockTimeout;

	NSUInteger _maximumUnlockAttempts;

	NSUserDefaults *_userDefaults;
	OCKeychain *_keychain;
}

@end

@implementation AppLock

@synthesize participateInLockTimeout = _participateInLockTimeout;
@synthesize maximumUnlockAttempts = _maximumUnlockAttempts;
@synthesize nextPossibleUnlockDate = _nextPossibleUnlockDate;

#pragma mark - Shared instance
+ (AppLock *)sharedAppLock
{
	static dispatch_once_t onceToken;
	static AppLock *sharedAppLock;

	dispatch_once(&onceToken, ^{
		sharedAppLock = [AppLock new];
	});

	return (sharedAppLock);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		_methods = [NSMutableArray new];

		_participateInLockTimeout = YES;

		_userDefaults = OCAppIdentity.sharedAppIdentity.userDefaults;
		_keychain = OCAppIdentity.sharedAppIdentity.keychain;

		_maximumUnlockAttempts = 3;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleLifecycleNotification:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleLifecycleNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleLifecycleNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleLifecycleNotification:) name:NSExtensionHostDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleLifecycleNotification:) name:NSExtensionHostWillEnterForegroundNotification object:nil];

		[OCIPNotificationCenter.sharedNotificationCenter addObserver:self forName:AppLockStateChangedNotification withHandler:^(OCIPNotificationCenter * _Nonnull notificationCenter, AppLock * _Nonnull appLock, OCIPCNotificationName  _Nonnull notificationName) {
			[appLock _updateLockState];
		}];
	}

	return (self);
}

- (void)dealloc
{
	[OCIPNotificationCenter.sharedNotificationCenter removeObserver:self forName:AppLockStateChangedNotification];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSExtensionHostDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSExtensionHostWillEnterForegroundNotification object:nil];
}

#pragma mark - Lifecycle notifications
- (void)_handleLifecycleNotification:(NSNotification *)notification
{
	NSNotificationName notificationName = notification.name;

	if ([notificationName isEqual:UIApplicationWillTerminateNotification])
	{
		// App will terminate
		[self enterLockTimeout];
	}

	if ([notificationName isEqual:UIApplicationDidEnterBackgroundNotification] || [notificationName isEqual:NSExtensionHostDidEnterBackgroundNotification])
	{
		// App did enter background, could be terminated
		[self enterLockTimeout];
	}

	if ([notificationName isEqual:UIApplicationWillEnterForegroundNotification] || [notificationName isEqual:NSExtensionHostWillEnterForegroundNotification])
	{
		// App will enter foreground
		[self leaveLockTimeout];
	}
}

#pragma mark - Status
- (BOOL)unlocked
{
	[self _updateLockState];
	return (_unlocked);
}

- (void)setUnlocked:(BOOL)unlocked
{
	_unlocked = unlocked;
}

- (NSDate *)lastUnlockDate
{
	return ([_userDefaults objectForKey:AppLockLastUnlockDateKey]);
}

- (void)setLastUnlockDate:(NSDate * _Nullable)lastUnlockDate
{
	[_userDefaults setObject:lastUnlockDate forKey:AppLockLastUnlockDateKey];
}

- (NSDate *)lastLockEventDate
{
	return  ([_userDefaults objectForKey:AppLockLastLockEventDateKey]);
}

- (void)setLastLockEventDate:(NSDate * _Nullable)lastLockEventDate
{
	[_userDefaults setObject:lastLockEventDate forKey:AppLockLastLockEventDateKey];
}

- (NSDate *)earliestUnlockDate
{
	return (nil);
}

- (void)_registerLockEventIfUnlocked
{
	if (self.unlocked)
	{
		self.lastLockEventDate = [NSDate new];
	}
}

#pragma mark - Settings
- (BOOL)enabled
{
	return ([_userDefaults boolForKey:AppLockLastEnabledKey]);
}

- (void)setEnabled:(BOOL)enabled
{
	[_userDefaults setBool:enabled forKey:AppLockLastEnabledKey];
}

- (NSTimeInterval)lockTimeout
{
	return (0);
}

- (void)setLockTimeout:(NSTimeInterval)timeout
{
}

#pragma mark - Methods
- (void)addMethod:(AppLockMethod *)method
{
	method.appLock = self;
	[_methods addObject:method];
}

- (void)removeMethod:(AppLockMethod *)method
{
	method.appLock = nil;
	[_methods removeObject:method];
}

- (nullable AppLockMethod *)methodForIdentifier:(AppLockMethodIdentifier)appLockMethodIdentifier
{
	return (nil);
}

#pragma mark - Attempt unlock
- (NSUInteger)failedUnlockAttempts
{
	return ([_userDefaults integerForKey:AppLockFailedUnlockAttemptsKey]);
}

- (void)setFailedUnlockAttempts:(NSUInteger)failedUnlockAttempts
{
	[_userDefaults setInteger:failedUnlockAttempts forKey:AppLockFailedUnlockAttemptsKey];
}

- (NSUInteger)remainingUnlockAttempts
{
	if (self.failedUnlockAttempts >= self.maximumUnlockAttempts)
	{
		return (0);
	}

	return (self.maximumUnlockAttempts - self.failedUnlockAttempts);
}

- (void)attemptUnlockByMethod:(AppLockMethod *)method withSuccess:(BOOL)success completionHandler:(void(^)(NSError *error))completionHandler
{
	NSDate *nextPossibleUnlockDate = self.nextPossibleUnlockDate;

	if ((nextPossibleUnlockDate!=nil) && ([nextPossibleUnlockDate timeIntervalSinceNow] > 0))
	{
		// Attempt before next possible unlock date => return error
		completionHandler(AppLockError(AppLockErrorActivePenalty));
	}

	if (success)
	{
		// Save unlock date and process
		self.lastUnlockDate = [NSDate new];

		// Reset failed unlock attempts
		self.failedUnlockAttempts = 0;

		// Reset earliest possible unlock date
		[self willChangeValueForKey:@"nextPossibleUnlockDate"];
		_nextPossibleUnlockDate = nil;
		[self didChangeValueForKey:@"nextPossibleUnlockDate"];

		// Update .unlocked
		[self willChangeValueForKey:@"unlocked"];
		_unlocked = YES;
		[self didChangeValueForKey:@"unlocked"];

		// Signal leaving lock timeout
		[self leaveLockTimeout];
	}
	else
	{
		self.failedUnlockAttempts = self.failedUnlockAttempts + 1;
		_lastUnlockAttempt = [NSDate new];
	}

	completionHandler(nil);
}

#pragma mark - Unlock sessions
- (NSArray<OCProcessSession *> *)unlockSessions
{
	NSData *unlockSessionsData=nil;
	NSError *error=nil;
	NSArray<OCProcessSession *> *unlockSessions=nil;

	if ((unlockSessionsData = [_userDefaults dataForKey:AppLockLastUnlockSessionsKey]) != nil)
	{
		 unlockSessions = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:OCProcessSession.class, NSArray.class, nil] fromData:unlockSessionsData error:&error];

		 if (error != nil)
		 {
		 	OCLogError(@"Error decoding unlockSessions: %@", OCLogPrivate(error));
		 }
	}

	return (unlockSessions);
}

- (void)setUnlockSessions:(NSArray<OCProcessSession *>)unlockSessions
{
	if ((unlockSessions != nil) && (unlockSessions.count > 0))
	{
		NSError *error = nil;
		NSData *unlockSessionsData;

		if ((unlockSessionsData = [NSKeyedArchiver archivedDataWithRootObject:unlockSessions requiringSecureCoding:YES error:&error]) != nil)
		{
			[_userDefaults setObject:unlockSessionsData forKey:AppLockLastUnlockSessionsKey];
		}
	}
}

- (BOOL)_modifyUnlockSessionsWithModifier:(BOOL(^)(NSMutableArray<OCProcessSession *> *sessions, OCProcessSession *currentSession, NSUInteger currentSessionIndex))modifier
{
	NSMutableArray <OCProcessSession *> *unlockSessions;
	BOOL didModify = NO;

	if ((unlockSessions = [[self unlockSessions] mutableCopy]) != nil)
	{
		OCProcessSession *currentSession;

		if ((currentSession = OCProcessManager.sharedProcessManager.processSession) != nil)
		{
			__block NSUInteger currentSessionIndex = NSNotFound;

			[unlockSessions enumerateObjectsUsingBlock:^(OCProcessSession * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				if ([session.uuid isEqual:currentSession.uuid])
				{
					currentSessionIndex = idx;
					*stop = YES;
				}
			}];

			if (didModify = modifier(unlockSessions, currentSession, currentSessionIndex))
			{
				self.unlockSessions = unlockSessions;
			}
		}
		else
		{
			OCLogError(@"AppLock couldn't get current processSession");
		}
	}

	return (didModify);
}

#pragma mark - Timeout
- (void)enterLockTimeout
{
	[self _updateLockState];

	if (self.participateInLockTimeout)
	{
		[self _modifyUnlockSessionsWithModifier:^BOOL(NSMutableArray<OCProcessSession *> *sessions, OCProcessSession *currentSession, NSUInteger currentSessionIndex) {
			// Remove process from unlock sessions
			if (currentSessionIndex != NSNotFound)
			{
				[unlockSessions removeObjectAtIndex:currentSessionIndex];
				return (YES);
			}

			return (NO);
		}];

		[self _registerLockEventIfUnlocked];
	}
}

- (void)leaveLockTimeout
{
	[self _updateLockState];

	if (self.unlocked && self.participateInLockTimeout)
	{
		[self _modifyUnlockSessionsWithModifier:^BOOL(NSMutableArray<OCProcessSession *> *sessions, OCProcessSession *currentSession, NSUInteger currentSessionIndex) {
			// Add process to unlock sessions
			if (currentSessionIndex == NSNotFound)
			{
				[unlockSessions addObject:currentSession];
				return (YES);
			}

			return (NO);
		}];

		[self _registerLockEventIfUnlocked];
	}
}

#pragma mark - State
- (void)_updateLockState
{
	BOOL newUnlocked = NO;

	if (!self.enabled)
	{
		// If AppLock is disabled, it's always unlocked
		newUnlocked = YES;
	}
	else
	{
		// Determine current AppLock state
		if (self.lastUnlockDate != nil)
		{
			if (([self.lastUnlockDate timeIntervalSinceNow] + self.lockTimeout) > 0)
			{
				// Less than .lockTimeout seconds have passed since .lastUnlockDate => unlocked
				newUnlocked = YES;
			}
			else
			{
				// More than .lockTimeout seconds have passed since .lastUnlockDate => check other factors
				if (([self.lastLockEventDate timeIntervalSinceNow] + self.lockTimeout) > 0)
				{
					// Less than .lockTimeout seconds have passed since .lastLockEventDate => unlocked
					newUnlocked = YES;
				}
				else
				{
					// More than .lockTimeout seconds have passed since .lastLockEventDate => check unlock sessions
					NSMutableIndexSet *removeSessionsAtIndexes = [NSMutableIndexSet new];
					dispatch_group_t pingGroup = dispatch_group_create();
					NSArray <OCProcessSession *> *processSessions = self.unlockSessions;
					NSMutableArray <OCProcessSession *> *updatedSessions = [NSMutableArray new];

					[processSessions enumerateObjectsUsingBlock:^(OCProcessSession * _Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
						dispatch_group_enter(pingGroup);

						[OCProcessManager.sharedProcessManager pingSession:session withTimeout:0.25 completionHandler:^(BOOL responded, OCProcessSession * _Nonnull latestSession) {
							if (!responded)
							{
								[removeSessionsAtIndexes addIndex:idx];
							}
							else
							{
								[updatedSessions addObject:latestSession];
							}

							dispatch_group_leave(pingGroup);
						}];
					}];

					dispatch_group_wait(pingGroup, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)));

					self.unlockSessions = updatedSessions;

					if (updatedSessions.count > 0)
					{
						newUnlocked = YES;
					}
				}
			}
		}
		else
		{
			// No valid unlock found => locked
			newUnlocked = NO;
		}
	}

	if (newUnlocked != _unlocked)
	{
		self.unlocked = newUnlocked;
	}
}

@end
