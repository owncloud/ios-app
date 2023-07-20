//
//  FileProviderContentEnumerator.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 05.05.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <ownCloudApp/ownCloudApp.h>

#import "FileProviderContentEnumerator.h"
#import "FileProviderEnumeratorObserver.h"
#import "OCItem+FileProviderItem.h"
#import "OCVFSNode+FileProviderItem.h"
#import "NSNumber+OCSyncAnchorData.h"

@interface OCVault (InternalSignal)
- (void)signalEnumeratorForContainerItemIdentifier:(NSFileProviderItemIdentifier)changedDirectoryLocalID;
@end

@implementation FileProviderContentEnumerator

#pragma mark - Queues
+ (dispatch_queue_t)dispatchQueue
{
	static dispatch_once_t onceToken;
	static dispatch_queue_t dispatchQueue;
	dispatch_once(&onceToken, ^{
		dispatchQueue = dispatch_queue_create("Enumeration queue", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
	});

	return (dispatchQueue);
}

+ (OCAsyncSequentialQueue *)queue
{
	static dispatch_once_t onceToken;
	static OCAsyncSequentialQueue *queue;

	dispatch_once(&onceToken, ^{
		dispatch_queue_t dispatchQueue = FileProviderContentEnumerator.dispatchQueue;

		queue = [[OCAsyncSequentialQueue alloc] init];
		queue.executor = ^(OCAsyncSequentialQueueJob  _Nonnull job, dispatch_block_t  _Nonnull completionHandler) {
			dispatch_async(dispatchQueue, ^{
				job(completionHandler);
			});
		};
	});

	return (queue);
}

#pragma mark - Initialization
- (instancetype)initWithVFSCore:(OCVFSCore *)vfsCore containerItemIdentifier:(OCVFSItemID)containerItemIdentifier;
{
	if ((self = [super init]) != nil)
	{
		_vfsCore = vfsCore;
		_containerItemIdentifier = containerItemIdentifier;

		_enumerationObservers = [NSMutableArray new];
		_changeObservers = [NSMutableArray new];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_displaySettingsChanged:) name:DisplaySettingsChanged object:nil];
	}

	return (self);
}

#pragma mark - Display settings change tracking
- (void)_displaySettingsChanged:(NSNotification *)notification
{
	OCLogDebug(@"Received display settings update notification (enumerator for %@)", _containerItemIdentifier);

	if (_content.query != nil)
	{
		[DisplaySettings.sharedDisplaySettings updateQueryWithDisplaySettings:_content.query];
	}

	if (_containerItemIdentifier != nil)
	{
		[_content.core.vault signalEnumeratorForContainerItemIdentifier:_containerItemIdentifier];
	}
}

#pragma mark - FileProvider API
- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
	OCLogDebug(@"##### Enumerate ITEMS for observer: %@ fromPage: %@", observer, page);

	__weak FileProviderContentEnumerator *weakSelf = self;

	[self requestContentWithErrorHandler:^(NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[observer finishEnumeratingWithError:error];
		});
	} contentConsumer:^(OCVFSContent *content) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf provideItemsToEnumerationObserver:observer fromContent:content];
		});
	} observerQueuer:^BOOL(dispatch_block_t completionHandler) {
		FileProviderContentEnumerator *strongSelf = weakSelf;

		if (strongSelf == nil) {
			return(NO);
		}

		FileProviderEnumeratorObserver *enumerationObserver = [FileProviderEnumeratorObserver new];

		enumerationObserver.enumerationObserver = observer;
		enumerationObserver.enumerationStartPage = page;
		enumerationObserver.enumerationCompletionHandler = completionHandler;

		[strongSelf->_enumerationObservers addObject:enumerationObserver];

		return (YES);
	}];

	/* TODO:
	- inspect the page to determine whether this is an initial or a follow-up request

	If this is an enumerator for a directory, the root container or all directories:
	- perform a server request to fetch directory contents
	If this is an enumerator for the active set:
	- perform a server request to update your local database
	- fetch the active set from your local database

	- inform the observer about the items returned by the server (possibly multiple times)
	- inform the observer that you are finished with this page
	*/
}

- (void)enumerateChangesForObserver:(id<NSFileProviderChangeObserver>)observer fromSyncAnchor:(NSFileProviderSyncAnchor)syncAnchor
{
	OCLogDebug(@"##### Enumerate CHANGES for observer: %@ fromSyncAnchor: %@", observer, syncAnchor);

	if (syncAnchor != nil)
	{
		/** Apple:
			If the enumeration fails with NSFileProviderErrorSyncAnchorExpired, we will
			drop all cached data and start the enumeration over starting with sync anchor
			nil.
		*/
		dispatch_async(dispatch_get_main_queue(), ^{
//			if ([syncAnchor isEqual:[self->_core.latestSyncAnchor syncAnchorData]])
//			{
//				OCLogDebug(@"##### END(LATEST) Enumerate CHANGES for observer: %@ fromSyncAnchor: %@", observer, syncAnchor);
//				[observer finishEnumeratingChangesUpToSyncAnchor:syncAnchor moreComing:NO];
//			}
//			else
			{
				OCLogDebug(@"##### END(EXPIRED) Enumerate CHANGES for observer: %@ fromSyncAnchor: %@", observer, syncAnchor);
				[observer finishEnumeratingWithError:[NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorSyncAnchorExpired userInfo:nil]];
			}
		});
	}
	else
	{
		/** Apple:
			"If anchor is nil, then the system is enumerating from scratch: the system wants
			to receives changes to reconstruct the list of items in this enumeration as if
			starting from an empty list."
		*/

		__weak FileProviderContentEnumerator *weakSelf = self;

		[self requestContentWithErrorHandler:^(NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[observer finishEnumeratingWithError:error];
			});
		} contentConsumer:^(OCVFSContent *content) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[weakSelf provideItemsForChangeObserver:observer fromContent:content];
			});
		} observerQueuer:^BOOL(dispatch_block_t completionHandler) {
			FileProviderContentEnumerator *strongSelf = weakSelf;

			if (strongSelf == nil) {
				return(NO);
			}

			FileProviderEnumeratorObserver *enumerationObserver = [FileProviderEnumeratorObserver new];

			enumerationObserver.changeObserver = observer;
			enumerationObserver.changesFromSyncAnchor = syncAnchor;
			enumerationObserver.enumerationCompletionHandler = completionHandler;

			[strongSelf->_changeObservers addObject:enumerationObserver];

			return (YES);
		}];
	}
}

- (void)invalidate
{
	OCLogDebug(@"##### INVALIDATE %@", _containerItemIdentifier);

	[[NSNotificationCenter defaultCenter] removeObserver:self name:DisplaySettingsChanged object:nil];

	self.content.query.delegate = nil;
	self.content = nil;
}

#pragma mark - Content retrieval
- (void)requestContentWithErrorHandler:(void(^)(NSError *))errorHandler contentConsumer:(void(^)(OCVFSContent *))contentConsumer observerQueuer:(BOOL(^)(dispatch_block_t completionHandler))observerQueuer
{
	__weak FileProviderContentEnumerator *weakSelf = self;
	OCVFSItemID containerItemIdentifier = _containerItemIdentifier;
	NSString *contentRequestUUID = [containerItemIdentifier stringByAppendingFormat:@"#%@", NSUUID.UUID.UUIDString];

	OCLogDebug(@"[QUEUE] Queuing content request %@", contentRequestUUID);

	[FileProviderContentEnumerator.queue async:^(dispatch_block_t  _Nonnull completionHandler) {
		FileProviderContentEnumerator *strongSelf = weakSelf;

		OCWLogDebug(@"[START] Starting content request %@", contentRequestUUID);

		// Add completion handler call debugging
		completionHandler = ^{
			OCWLogDebug(@"[CMPHL] Completion handler called for request %@, stack trace: %@", contentRequestUUID, NSThread.callStackSymbols);
			completionHandler();
		};

		if (strongSelf == nil) {
			OCWLogDebug(@"[CMPLT] Content Enumerator deallocated before content could be returned for %@", contentRequestUUID);
			errorHandler(OCErrorWithDescription(OCErrorInternal, @"Content Enumerator deallocated before content could be returned"));

			completionHandler();
			return;
		}

		[strongSelf.vfsCore provideContentForContainerItemID:containerItemIdentifier changesFromSyncAnchor:nil completionHandler:^(NSError * _Nullable error, OCVFSContent * _Nullable content) {
			OCWLogDebug(@"[HAND1] Handling response for content request %@", contentRequestUUID);

			dispatch_async(FileProviderContentEnumerator.dispatchQueue, ^{
				FileProviderContentEnumerator *strongSelf = weakSelf;

				OCWLogDebug(@"[HAND2] Handling response for content request %@", contentRequestUUID);

				if (strongSelf == nil) {
					OCWLogDebug(@"[ERROR] Content Enumerator deallocated before content could be returned for %@", contentRequestUUID);
					errorHandler(OCErrorWithDescription(OCErrorInternal, @"Content Enumerator deallocated before content could be returned"));

					completionHandler();
					return;
				}

				if (error != nil)
				{
					OCWLogDebug(@"[ERROR] Content Enumerator VFS response error %@ for %@", error, contentRequestUUID);
					errorHandler(error);
				}
				else
				{
					if (content.isSnapshot)
					{
						// Content is a snapshot, so there's no need to keep the content around - it can be sent now
						OCWLogDebug(@"[CMPLT] Content Enumerator VFS snapshot response for %@", contentRequestUUID);
						contentConsumer(content);
					}
					else
					{
						// Content is self-updating, so we can send it
						if (strongSelf.content != nil)
						{
							// Content already available
							OCWLogDebug(@"[CMPLT] Content Enumerator VFS immediately available content response for %@", contentRequestUUID);
							contentConsumer(strongSelf.content);
						}
						else
						{
							// Content to be provided by observer
							OCWLogDebug(@"[REQST] Content Enumerator VFS provided asynchronously for %@", contentRequestUUID);
							strongSelf.content = content; // effectively sets it to nil, since this can only be reached following (strongSelf.content == nil)

							if (!observerQueuer(nil))
							{
								// No observer available - unexpected, so complete with an error
								OCWLogDebug(@"[ERROR] No content observer available for %@", contentRequestUUID);
								errorHandler(OCErrorWithDescription(OCErrorInternal, @"No content observer available"));
							}
						}
					}
				}

				completionHandler();
			});
		}];
	}];
}

- (void)setContent:(OCVFSContent *)content
{
	if (content != nil)
	{
		if (content.query != nil)
		{
			[content.core stopQuery:content.query];
			content.query.delegate = nil;
		}
	}

	_content = content;

	if ((content.core != nil) && (content.query != nil))
	{
		content.query.delegate = self;

		[DisplaySettings.sharedDisplaySettings updateQueryWithDisplaySettings:content.query];

		@synchronized(self)
		{
			if ([self->_enumerationObservers.lastObject.enumerationStartPage isEqual:NSFileProviderInitialPageSortedByDate])
			{
				content.query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
					return ([item1.lastModified compare:item2.lastModified]);
				};
			}

			if ([self->_enumerationObservers.lastObject.enumerationStartPage isEqual:NSFileProviderInitialPageSortedByName])
			{
				content.query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
					return ([item1.name compare:item2.name]);
				};
			}
		}

		[content.core startQuery:content.query];
	}

////		OCMeasureEventBegin(self, @"fp.enumerator", coreRequestRef, @"Requesting core…");
////		OCMeasureEventEnd(self, @"fp.enumerator", coreRequestRef, @"Received core…");
////			if (self->_core != nil)
////			{
////				// Already has a core - balance duplicate requested core
////				[[OCCoreManager sharedCoreManager] returnCoreForBookmark:core.bookmark completionHandler:nil];
////			}
////			else
////			{
////				self->_core = core;
////			}
//
////			if (error != nil)
////			{
////				// TODO: Report error as NSFileProviderErrorServerUnreachable or NSFileProviderErrorNotAuthenticated, depending on what the underlying error is
////				[self _finishAllEnumeratorsWithError:error];
////			}
////			else
////			{
//				// Create and add query
//				__block OCPath queryPath = nil;
//
//				OCMeasureEventBegin(self, @"db.resolve-item", resolveEventRef, @"Resolve item identifier");
//
////				if ([self->_enumeratedItemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
////				{
////					queryPath = @"/";
////				}
////				else
//				{
//					NSError *error = nil;
//					OCItem *item;
//
//					if ((item = [core synchronousRetrieveItemFromDatabaseForLocalID:self->_enumeratedItemIdentifier syncAnchor:NULL error:&error]) != nil)
//					{
//						if (item.type == OCItemTypeCollection)
//						{
//							queryPath = item.path;
//						}
////
////						if (item.type == OCItemTypeFile)
////						{
////							OCLogDebug(@"Observe item: %@", item);
////
////							[observer didEnumerateItems:@[ item ]];
////							[observer finishEnumeratingUpToPage:nil];
////							return;
////						}
//					}
//				}
//
//				OCMeasureEventEnd(self, @"db.resolve-item", resolveEventRef, @"Resolve item identifier");
//
//				if (queryPath == nil)
//				{
//					// Item not found or not a directory
//					NSError *enumerationError = [NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorNoSuchItem userInfo:nil];
//
//					[self _finishAllEnumeratorsWithError:enumerationError];
//					return;
//				}
//				else
//				{
//					// Start query
//					self->_query = [OCQuery queryForLocation:[OCLocation legacyRootPath:queryPath]];
//					self->_query.includeRootItem = queryPath.isRootPath; // Include the root item only for the root folder. If it's not included, no folder can be created in the root directory. If a non-root folder is included in a query result for its content, the Files Duplicate action will loop infinitely.
//					self->_query.delegate = self;
//
//					[DisplaySettings.sharedDisplaySettings updateQueryWithDisplaySettings:self->_query];
//
//					@synchronized(self)
//					{
//						if ([self->_enumerationObservers.lastObject.enumerationStartPage isEqual:NSFileProviderInitialPageSortedByDate])
//						{
//							self->_query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
//								return ([item1.lastModified compare:item2.lastModified]);
//							};
//						}
//
//						if ([self->_enumerationObservers.lastObject.enumerationStartPage isEqual:NSFileProviderInitialPageSortedByName])
//						{
//							self->_query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
//								return ([item1.name compare:item2.name]);
//							};
//						}
//					}
//
//					OCLogDebug(@"##### START QUERY FOR %@", self->_query.queryLocation);
//
//					[self->_query attachMeasurement:self->_measurement];
//
//					[core startQuery:self->_query];
//				}
//			}
//		}];
//	}
//	else
//	{
//		OCLogDebug(@"Query already running..");
//
//		if (_query != nil)
//		{
//			@synchronized(self)
//			{
//				if (_enumerationObservers.count!=0)
//				{
//					dispatch_async(dispatch_get_main_queue(), ^{
//						[self provideItemsForEnumerationObserverFromQuery:self->_query];
//					});
//				}
//
//				if (_changeObservers.count!=0)
//				{
//					dispatch_async(dispatch_get_main_queue(), ^{
//						[self provideItemsForChangeObserverFromQuery:self->_query];
//					});
//				}
//			}
//		}
//	}


//			if (error != nil)
//			{
//				[observer finishEnumeratingWithError:error];
//			}
//			else
//			{
//				self.content = content;
//
//				// Send VFS children
//				if (content.vfsChildNodes.count > 0)
//				{
//					[observer didEnumerateItems:content.vfsChildNodes];
//				}
//
//				// End enumeration if no query returned
//				if (content.query == nil)
//				{
//					[observer finishEnumeratingUpToPage:nil];
//				}
//
//				// Continue enumeration if query returned
//				if (content.query != nil)
//				{
//				}
//			}
}

//- (void)_startQuery
//{
//	OCLogDebug(@"##### Starting query..");
//
//	OCMeasureEvent(self, @"fp.enumerator", @"Starting enumerator…");
//
//	BOOL contentRequested = NO;
//
//	@synchronized(self)
//	{
//		contentRequested = _contentRequested;
//
//		if (_contentRequested == NO)
//		{
//			_contentRequested = YES;
//		}
//	}
//
//	if ((self.content == nil) && !contentRequested)
//	{
//		[self.vfsCore provideContentForContainerItemID:_containerItemIdentifier changesFromSyncAnchor:nil completionHandler:^(NSError * _Nullable error, OCVFSContent * _Nullable content) {
//			if (error != nil)
//			{
//				[self _finishAllEnumeratorsWithError:error];
//			}
//			else
//			{
//				if (content.isSnapshot)
//				{
//					// No query that would call us back later, so just send the existing content now
//					[self sendContent:content];
//
//					@synchronized(self)
//					{
//						self->_contentRequested = NO;
//					}
//				}
//				else
//				{
//					// There will be callbacks from the query, no need to send content now already
//					self.content = content;
//				}
//			}
//		}];
//	}
//	else
//	{
//		OCLogDebug(@"Query already running..");
//		[self sendContent:self.content];
//	}
//
//}

//- (void)sendContent:(OCVFSContent *)content
//{
//	if (content != nil)
//	{
//		@synchronized(self)
//		{
//			if (_enumerationObservers.count!=0)
//			{
//				dispatch_async(dispatch_get_main_queue(), ^{
//					[self provideItemsForEnumerationObserverFromContent:content];
//				});
//			}
//
//			if (_changeObservers.count!=0)
//			{
//				dispatch_async(dispatch_get_main_queue(), ^{
//					[self provideItemsForChangeObserverFromConten:content];
//				});
//			}
//		}
//	}
//}

#pragma mark - Content distribution
- (BOOL)provideItemsToEnumerationObserver:(id<NSFileProviderEnumerationObserver>)enumerationObserver fromContent:(OCVFSContent *)content
{
	if (((content.query.state == OCQueryStateContentsFromCache) || ((content.query.state == OCQueryStateWaitingForServerReply) && (content.query.queryResults.count > 0)) || (content.query.state == OCQueryStateIdle))
	    || ((content.query == nil) && (content != nil)))
	{
		NSArray <OCItem *> *queryResults = content.query.queryResults;
		OCBookmarkUUIDString bookmarkUUIDString = content.core.bookmark.uuid.UUIDString;

		for (OCItem *item in queryResults)
		{
			item.bookmarkUUID = bookmarkUUIDString;
		}

		OCLogDebug(@"##### PROVIDE ITEMS TO %ld --ENUMERATION-- OBSERVER %@ FOR %@: %@", _enumerationObservers.count, enumerationObserver, content.query.queryLocation.path, queryResults);

		dispatch_async(dispatch_get_main_queue(), ^{
			if (content.vfsChildNodes.count > 0)
			{
				[enumerationObserver didEnumerateItems:content.vfsChildNodes];
			}

			if (queryResults.count > 0)
			{
				[enumerationObserver didEnumerateItems:queryResults];
			}

			[enumerationObserver finishEnumeratingUpToPage:nil];
		});

		return (YES);
	}

	return (NO);
}

- (BOOL)provideItemsForChangeObserver:(id<NSFileProviderChangeObserver>)changeObserver fromContent:(OCVFSContent *)content
{
	OCLogDebug(@"##### PROVIDE ITEMS TO %lu --CHANGE-- OBSERVER FOR %@: %@", _changeObservers.count, content.query.queryLocation.path, content.query.queryResults);

	NSArray <OCItem *> *queryResults = content.query.queryResults;
	OCBookmarkUUIDString bookmarkUUIDString = content.core.bookmark.uuid.UUIDString;

	for (OCItem *item in queryResults)
	{
		item.bookmarkUUID = bookmarkUUIDString;
	}

	NSFileProviderSyncAnchor syncAnchor = [content.core.latestSyncAnchor syncAnchorData];

	dispatch_async(dispatch_get_main_queue(), ^{
		[changeObserver didUpdateItems:queryResults];
		[changeObserver finishEnumeratingChangesUpToSyncAnchor:syncAnchor moreComing:NO];
	});

	return (YES);
}

#pragma mark - OCQuery delegate
- (void)queryHasChangesAvailable:(OCQuery *)query
{
	OCLogDebug(@"##### Query for %@ has changes. Query state: %lu, SinceSyncAnchor: %@, Changes available: %d", query.queryLocation.path, (unsigned long)query.state, query.querySinceSyncAnchor, query.hasChangesAvailable);

	if ( (query.state == OCQueryStateContentsFromCache) ||
	    ((query.state == OCQueryStateWaitingForServerReply) && (query.queryResults.count > 0)) ||
	     (query.state == OCQueryStateIdle))
	{
		dispatch_async(FileProviderContentEnumerator.dispatchQueue, ^{
			// Send content to enumeration observers
			NSArray<FileProviderEnumeratorObserver *> *enumerationObservers = [self->_enumerationObservers copy];

			for (FileProviderEnumeratorObserver *observer in enumerationObservers)
			{
				if ([self provideItemsToEnumerationObserver:observer.enumerationObserver fromContent:self.content])
				{
					[observer completeEnumeration];
					[self->_enumerationObservers removeObject:observer];
				}
			}


			// Send content to change observers
			NSArray<FileProviderEnumeratorObserver *> *changeObservers = [self->_changeObservers copy];

			for (FileProviderEnumeratorObserver *observer in changeObservers)
			{
				if ([self provideItemsForChangeObserver:observer.changeObserver fromContent:self.content])
				{
					[observer completeEnumeration];
					[self->_changeObservers removeObject:observer];
				}
			}
		});
	}
}

- (void)query:(OCQuery *)query failedWithError:(NSError *)error
{
	OCLogDebug(@"### Query failed with error: %@", error);
}

//- (void)currentSyncAnchorWithCompletionHandler:(void (^)(NSFileProviderSyncAnchor _Nullable))completionHandler
//{
//	OCLogDebug(@"#### Request current sync anchor");
//
//	dispatch_async(dispatch_get_main_queue(), ^{
//		completionHandler([self->_core.latestSyncAnchor syncAnchorData]);
//	});
//}

// - (void)enumerateChangesForObserver:(id<NSFileProviderChangeObserver>)observer fromSyncAnchor:(NSFileProviderSyncAnchor)anchor
// {
	/* TODO:
	- query the server for updates since the passed-in sync anchor

	If this is an enumerator for the active set:
	- note the changes in your local database

	- inform the observer about item deletions and updates (modifications + insertions)
	- inform the observer when you have finished enumerating up to a subsequent sync anchor
	*/
	/**
	If the enumeration fails with NSFileProviderErrorSyncAnchorExpired, we will
	drop all cached data and start the enumeration over starting with sync anchor
	nil.
	*/
	// - (void)finishEnumeratingWithError:(NSError *)error;
// }

//- (OCMeasurement *)hostedMeasurement
//{
//	return (_measurement);
//}

#pragma mark - Log tags
+ (NSArray<OCLogTagName> *)logTags
{
	return (@[ @"FPEnum" ]);
}

- (NSArray<OCLogTagName> *)logTags
{
	return (@[ @"FPEnum", OCLogTagInstance(self)]);
}

@end
