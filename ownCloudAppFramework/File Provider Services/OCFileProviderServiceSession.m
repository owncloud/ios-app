//
//  OCFileProviderServiceSession.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 06.08.20.
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
#import "OCFileProviderServiceSession.h"
#import "OCFileProviderService.h"
#import "OCVault+FPServices.h"
#import "OCBookmark+FPServices.h"

@interface OCFileProviderServiceSession ()
{
	OCAsyncSequentialQueue *_queue;

	id<OCFileProviderServicesHost> _host;
	dispatch_block_t _doneHandler;

	NSMutableDictionary<NSUUID *, OCFileProviderServiceSessionErrorHandler> *_errorHandlers;

	NSInteger _usageCount;
}
@end

@implementation OCFileProviderServiceSession

+ (void)acquireFileProviderServicesHostWithURL:(NSURL *)serviceURL completionHandler:(void(^)(NSError * _Nullable error, id<OCFileProviderServicesHost> _Nullable, void(^ _Nullable doneHandler)(void)))completionHandler errorHandler:(OCFileProviderServiceSessionErrorHandler)errorHandler
{
	[NSFileManager.defaultManager createDirectoryAtURL:serviceURL withIntermediateDirectories:YES attributes:nil error:NULL];
	[NSFileManager.defaultManager getFileProviderServicesForItemAtURL:serviceURL completionHandler:^(NSDictionary<NSFileProviderServiceName,NSFileProviderService *> * _Nullable services, NSError * _Nullable error) {
		NSFileProviderService *service;

		if ((service = services[OCFileProviderServiceName]) != nil)
		{
			[service getFileProviderConnectionWithCompletionHandler:^(NSXPCConnection * _Nullable connection, NSError * _Nullable error) {
				if (error == nil)
				{
					__weak NSXPCConnection *weakConnection = connection;

					connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OCFileProviderServicesHost)];
					connection.interruptionHandler = ^{
						[weakConnection invalidate];
					};
					[connection resume];
				}

				id<OCFileProviderServicesHost> remoteObjectProxy = [connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
					OCLogError(@"File Provider Services proxy connection error: %@", error);
					errorHandler(error);
				}];

				completionHandler(error, (id<OCFileProviderServicesHost>)remoteObjectProxy, ^{
					[connection invalidate];
				});
			}];
		}
		else
		{
			OCLogError(@"File Provider Service unavailable: %@", error);
			errorHandler(error);
		}
	}];
}

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
	if ((self = [super init]) != nil)
	{
		_serviceURL = serviceURL;

		_errorHandlers = [NSMutableDictionary new];

		_queue = [OCAsyncSequentialQueue new];
		_queue.executor = ^(OCAsyncSequentialQueueJob  _Nonnull job, dispatch_block_t  _Nonnull completionHandler) {
			job(completionHandler);
		};
	}

	return (self);
}

- (instancetype)initWithVault:(OCVault *)vault
{
	if ((self = [self initWithServiceURL:vault.fpServicesURL]) != nil)
	{
		_vault = vault;
	}

	return (self);
}

- (instancetype)initWithBookmark:(OCBookmark *)bookmark
{
	return ([self initWithServiceURL:[[OCVault alloc] initWithBookmark:bookmark].fpServicesURL]);
}

- (void)dealloc
{
	if (_doneHandler != nil)
	{
		OCLogWarning(@"Premature deallocation of OCFileProviderServiceSession: forgot a call to doneHandler or to hold a strong reference to %@?", self);

		_host = nil;

		_doneHandler();
		_doneHandler = nil;
	}
}

- (void)handleError:(NSError *)error
{
	@synchronized(self)
	{
		for (NSUUID *uuid in _errorHandlers)
		{
			_errorHandlers[uuid](error);
		}
	}
}

- (void)acquireFileProviderServicesHostWithCompletionHandler:(void(^)(NSError * _Nullable error, id<OCFileProviderServicesHost> _Nullable, void(^ _Nullable doneHandler)(void)))completionHandler errorHandler:(OCFileProviderServiceSessionErrorHandler)errorHandler
{
	__weak OCFileProviderServiceSession *weakSelf = self;

	[_queue async:^(dispatch_block_t  _Nonnull queueCompletionHandler) {
		NSUUID *uuid = [NSUUID new];
		OCFileProviderServiceSession *session;

		dispatch_block_t doneHandler = ^{
			OCFileProviderServiceSession *session;

			if ((session = weakSelf) != nil)
			{
				@synchronized(session)
				{
					session->_errorHandlers[uuid] = nil;
				}
				[session releaseFileProviderService];
			}
		};

		if ((session = weakSelf) != nil)
		{
			@synchronized(session)
			{
				session->_errorHandlers[uuid] = [errorHandler copy];
			}

			session->_usageCount++;

			if (session->_usageCount == 1)
			{
				[OCFileProviderServiceSession acquireFileProviderServicesHostWithURL:session->_serviceURL completionHandler:^(NSError * _Nullable error, id<OCFileProviderServicesHost> _Nullable host, void (^ _Nullable hostDoneHandler)(void)) {
					OCFileProviderServiceSession *session;

					if ((session = weakSelf) != nil)
					{
						session->_host = host;
						session->_doneHandler = [hostDoneHandler copy];

						[session->_queue async:^(dispatch_block_t  _Nonnull innerQueueCompletionHandler) {
							completionHandler(error, host, ^{
								doneHandler();
								innerQueueCompletionHandler();
							});
						}];
					}
					else
					{
						completionHandler(OCError(OCErrorInternal), nil, nil);
					}

					queueCompletionHandler();
				} errorHandler:^(NSError *error) {
					[weakSelf handleError:error];
					queueCompletionHandler();
				}];
			}
			else
			{
				completionHandler(nil, session->_host, doneHandler);

				queueCompletionHandler();
			}
		}
	}];
}

- (void)releaseFileProviderService
{
	__weak OCFileProviderServiceSession *weakSelf = self;

	[_queue async:^(dispatch_block_t  _Nonnull queueCompletionHandler) {
		OCFileProviderServiceSession *session;

		if ((session = weakSelf) != nil)
		{
			session->_usageCount--;

			if (session->_usageCount == 0)
			{
				if (session->_doneHandler != nil)
				{
					session->_doneHandler();
					session->_doneHandler = nil;
				}

				session->_host = nil;

				@synchronized(session)
				{
					[session->_errorHandlers removeAllObjects];
				}
			}
		}

		queueCompletionHandler();
	}];
}

- (void)incrementSessionUsage
{
	_usageCount++;
}

- (void)decrementSessionUsage
{
	[self releaseFileProviderService];
}

@end
