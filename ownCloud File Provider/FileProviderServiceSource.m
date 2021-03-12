//
//  FileProviderServiceSource.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 22.07.20.
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

#import "FileProviderServiceSource.h"
#import <ownCloudApp/ownCloudApp.h>
#import <ownCloudSDK/ownCloudSDK.h>

@interface OCCore (setNeedsToProcessSyncRecords)
- (void)setNeedsToProcessSyncRecords;
@end

@interface FileProviderServiceSource () <NSXPCListenerDelegate, OCFileProviderServicesHost>
{
	NSFileProviderServiceName _serviceName;
	NSXPCListener *_listener;
	OCBookmark *_bookmark;
	__weak OCCore *_core;
}
@end

@implementation FileProviderServiceSource

@synthesize serviceName = _serviceName;

- (instancetype)initWithServiceName:(NSString *)serviceName extension:(FileProviderExtension *)fileProviderExtension
{
	if ((self = [super init]) != nil)
	{
		_serviceName = serviceName;
		_fileProviderExtension = fileProviderExtension;
		_bookmark = _fileProviderExtension.bookmark;
	}

	return (self);
}

- (void)dealloc
{
	OCLogDebug(@"FileProviderServiceSource Dealloc");

	if ((_bookmark != nil) && (_core != nil))
	{
		[OCCoreManager.sharedCoreManager returnCoreForBookmark:_bookmark completionHandler:nil];
	}

	[_listener invalidate];
}

- (NSXPCListenerEndpoint *)makeListenerEndpointAndReturnError:(NSError *__autoreleasing  _Nullable *)error
{
	if (_listener == nil)
	{
		_listener = [NSXPCListener anonymousListener];
		_listener.delegate = self;

		[_listener resume];
	}

	if ((_listener == nil) && (error != NULL))
	{
		*error = OCError(OCErrorUnknown);
	}

	return (_listener.endpoint);
}

#pragma mark - Listener delegate
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
	NSXPCInterface *hostInterface;

	__weak NSXPCConnection *weakConnection = newConnection;

	hostInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OCFileProviderServicesHost)];

	newConnection.exportedInterface = hostInterface;
	newConnection.exportedObject = self;
	newConnection.interruptionHandler = ^{
		OCLogWarning(@"XPC connection interrupted - invalidating..");
		[weakConnection invalidate];
	};

	OCLogDebug(@"FileProviderServiceSource[%p].shouldAcceptNewConnection[enter]", self.fileProviderExtension);

	[OCCoreManager.sharedCoreManager requestCoreForBookmark:_bookmark setup:nil completionHandler:^(OCCore * _Nullable core, NSError * _Nullable error) {
		self->_core = core;

		[core scheduleInCoreQueue:^{
			OCLogDebug(@"FileProviderServiceSource[%p].shouldAcceptNewConnection[done]", self.fileProviderExtension);
			[newConnection resume];
		}];
	}];

	OCLogDebug(@"FileProviderServiceSource[%p].shouldAcceptNewConnection[core]: %@", self.fileProviderExtension, self.fileProviderExtension.core);

	return (YES);
}

#pragma mark - Service API
- (nullable NSProgress *)importItemNamed:(nullable NSString *)newFileName at:(OCItem *)parentItem fromURL:(NSURL *)inputFileURL isSecurityScoped:(BOOL)isSecurityScoped importByCopying:(BOOL)importByCopying automaticConflictResolutionNameStyle:(OCCoreDuplicateNameStyle)nameStyle placeholderCompletionHandler:(void(^)(NSError * _Nullable error))completionHandler
{
	OCLogDebug(@"FileProviderServiceSource[%p].importItemNamed:%@ at:%@ fromURL:%@ isSecurityScoped:%d importByCopying:%d automaticConflictResolutionNameStyle:%lu", self.fileProviderExtension, newFileName, parentItem, inputFileURL, isSecurityScoped, importByCopying, (unsigned long)nameStyle);

	return ([_core importItemNamed:newFileName
				    at:parentItem
			       fromURL:inputFileURL
		      isSecurityScoped:isSecurityScoped
			       options:@{
				       OCCoreOptionImportByCopying : @(importByCopying),
				       OCCoreOptionAutomaticConflictResolutionNameStyle : @(nameStyle)
			       }
	  placeholderCompletionHandler:^(NSError * _Nullable error, OCItem * _Nullable item) {
		completionHandler(error);
	} resultHandler:nil]);
}

- (nullable NSProgress *)reportLocalModificationOfItem:(OCItem *)item parentItem:(OCItem *)parentItem withContentsOfFileAtURL:(NSURL *)inputFileURL lastModifiedDate:(nullable NSDate *)lastModifiedDate isSecurityScoped:(BOOL)isSecurityScoped placeholderCompletionHandler:(void(^)(NSError * _Nullable error))completionHandler
{
	NSDictionary<OCCoreOption,id> *options = nil;

	OCLogDebug(@"FileProviderServiceSource[%p].reportLocalModificationOfItem:%@ parentItem:%@ withContentsOfFileAtURL:%@ isSecurityScoped:%d", self.fileProviderExtension, item, parentItem, inputFileURL, isSecurityScoped);

	if (lastModifiedDate != nil)
	{
		options = @{
			OCCoreOptionLastModifiedDate : lastModifiedDate
		};
	}

	return ([_core reportLocalModificationOfItem:item
					  parentItem:parentItem
			     withContentsOfFileAtURL:inputFileURL
				    isSecurityScoped:isSecurityScoped
					     options:options
			placeholderCompletionHandler:^(NSError * _Nullable error, OCItem * _Nullable item) {
							completionHandler(error);
						     }
				       resultHandler:nil]);
}

- (void)processSyncRecordsIfNeeded
{
	OCLogDebug(@"Process sync records if needed for %@", _fileProviderExtension.core);
	[_core setNeedsToProcessSyncRecords];
}

@end
