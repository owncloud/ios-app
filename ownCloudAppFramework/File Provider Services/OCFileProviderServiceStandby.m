//
//  OCFileProviderServiceStandby.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 17.12.20.
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

#import "OCFileProviderServiceStandby.h"
#import "OCFileProviderServiceSession.h"

@interface OCFileProviderServiceStandby ()
{
	OCFileProviderServiceSession *_session;
	__weak id<OCFileProviderServicesHost> _host;
	BOOL _sessionUsageIncremented;
}
@end

@implementation OCFileProviderServiceStandby

- (instancetype)initWithCore:(OCCore *)core
{
	if ((self = [super init]) != nil)
	{
		if (OCVault.hostHasFileProvider)
		{
			_session = [[OCFileProviderServiceSession alloc] initWithBookmark:core.bookmark];

			[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_appStateChange:) name:UIApplicationDidBecomeActiveNotification object:nil];
		}
	}

	return (self);
}

- (void)start
{
	[_session acquireFileProviderServicesHostWithCompletionHandler:^(NSError * _Nullable error, id<OCFileProviderServicesHost> _Nullable host, void (^ _Nullable doneHandler)(void)) {
		OCLogDebug(@"Acquired file provider service with host=%@, error=%@", host, error);

		// Keep session open
		if (error == nil)
		{
			[self->_session incrementSessionUsage];
			self->_host = host;
			self->_sessionUsageIncremented = YES;
		}

		// Trigger sync record processing
		[host processSyncRecordsIfNeeded];

		if (doneHandler != nil)
		{
			doneHandler();
		}
	} errorHandler:^(NSError * _Nonnull error) {
		OCLogDebug(@"Error acquiring file provider service: %@", error);
	}];
}

- (void)stop
{
	_host = nil;

	if (_sessionUsageIncremented)
	{
		_sessionUsageIncremented = NO;

		OCLogDebug(@"Decrementing session usage for file provider service");

		// Balance previous retainSession() call and allow session to close
		[_session decrementSessionUsage];
	}
}

- (void)_appStateChange:(NSNotification *)notification
{
	if (_host != nil)
	{
		OCLogDebug(@"Sending processSyncRecordsIfNeeded to file provider service");
		[_host processSyncRecordsIfNeeded];
	}
}

@end
