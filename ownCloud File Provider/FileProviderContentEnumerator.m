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

- (instancetype)initWithVFSCore:(OCVFSCore *)vfsCore containerItemIdentifier:(NSFileProviderItemIdentifier)containerItemIdentifier;
{
	if ((self = [super init]) != nil)
	{
		_vfsCore = vfsCore;
		_containerItemIdentifier = containerItemIdentifier;

		_enumerationObservers = [NSMutableArray new];
		_changeObservers = [NSMutableArray new];

		if ([_containerItemIdentifier isEqual:NSFileProviderRootContainerItemIdentifier])
		{
			_containerItemIdentifier = _vfsCore.rootNode.itemID;
		}

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_displaySettingsChanged:) name:DisplaySettingsChanged object:nil];
	}

	return (self);
}

- (void)invalidate
{
	OCLogDebug(@"##### INVALIDATE %@", _containerItemIdentifier);

	[[NSNotificationCenter defaultCenter] removeObserver:self name:DisplaySettingsChanged object:nil];

	self.content.query.delegate = nil;
	self.content = nil;
}

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

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
	FileProviderEnumeratorObserver *enumerationObserver = [FileProviderEnumeratorObserver new];

	OCLogDebug(@"##### Enumerate ITEMS for observer: %@ fromPage: %@", observer, page);

	enumerationObserver.enumerationObserver = observer;
	enumerationObserver.enumerationStartPage = page;
	enumerationObserver.didProvideInitialItems = NO;

	@synchronized(self)
	{
		[self->_enumerationObservers addObject:enumerationObserver];
	}

	[self _startQuery];
}

//- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
//{
//	if ([_containerItemIdentifier isEqual:NSFileProviderRootContainerItemIdentifier])
//	{
//		_containerItemIdentifier = _vfsCore.rootNode.itemID;
//	}
//
//	[_vfsCore provideContentForContainerItemID:_containerItemIdentifier changesFromSyncAnchor:nil completionHandler:^(NSError * _Nullable error, OCVFSContent * _Nullable content) {
//		if (error != nil)
//		{
//			[observer finishEnumeratingWithError:error];
//		}
//		else
//		{
//			self.content = content;
//
//			// Send VFS children
//			if (content.vfsChildNodes.count > 0)
//			{
//				[observer didEnumerateItems:content.vfsChildNodes];
//			}
//
//			// End enumeration if no query returned
//			if (content.query == nil)
//			{
//				[observer finishEnumeratingUpToPage:nil];
//			}
//
//			// Continue enumeration if query returned
//			if (content.query != nil)
//			{
//				FileProviderEnumeratorObserver *enumerationObserver = [FileProviderEnumeratorObserver new];
//
//				OCLogDebug(@"##### Enumerate ITEMS for observer: %@ fromPage: %@", observer, page);
//
//				enumerationObserver.enumerationObserver = observer;
//				enumerationObserver.enumerationStartPage = page;
//				enumerationObserver.didProvideInitialItems = NO;
//
//				@synchronized(self)
//				{
//					[self->_enumerationObservers addObject:enumerationObserver];
//				}
//
//				[self _startQuery];
//			}
//		}
//	}];
//}

- (void)_finishAllEnumeratorsWithError:(NSError *)error
{
	@synchronized(self)
	{
		for (FileProviderEnumeratorObserver *observer in _enumerationObservers)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[observer.enumerationObserver finishEnumeratingWithError:error];
			});
		}
		[_enumerationObservers removeAllObjects];

		for (FileProviderEnumeratorObserver *observer in _changeObservers)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[observer.changeObserver finishEnumeratingWithError:error];
			});
		}
		[_changeObservers removeAllObjects];
	}
}

- (void)setContent:(OCVFSContent *)content
{
	if (content != nil)
	{
		if (content.query != nil)
		{
			[content.core stopQuery:content.query];
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

- (void)_startQuery
{
	OCLogDebug(@"##### Starting query..");

	OCMeasureEvent(self, @"fp.enumerator", @"Starting enumerator…");

	BOOL contentRequested = NO;

	@synchronized(self)
	{
		contentRequested = _contentRequested;

		if (_contentRequested == NO)
		{
			_contentRequested = YES;
		}
	}

	if ((self.content == nil) && !contentRequested)
	{
		[self.vfsCore provideContentForContainerItemID:_containerItemIdentifier changesFromSyncAnchor:nil completionHandler:^(NSError * _Nullable error, OCVFSContent * _Nullable content) {
			if (error != nil)
			{
				[self _finishAllEnumeratorsWithError:error];
			}
			else
			{
				self.content = content;

				if (self.content.query == nil)
				{
					// No query that would call us back later, so just send the existing content now
					[self sendExistingContent];
				}
			}
		}];
	}
	else
	{
		OCLogDebug(@"Query already running..");
		[self sendExistingContent];
	}

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

- (void)sendExistingContent
{
	if (self.content != nil)
	{
		@synchronized(self)
		{
			if (_enumerationObservers.count!=0)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self provideItemsForEnumerationObserver];
				});
			}

			if (_changeObservers.count!=0)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self provideItemsForChangeObserver];
				});
			}
		}
	}
}

- (void)provideItemsForEnumerationObserver
{
	if (((_content.query.state == OCQueryStateContentsFromCache) || ((_content.query.state == OCQueryStateWaitingForServerReply) && (_content.query.queryResults.count > 0)) || (_content.query.state == OCQueryStateIdle))
	    || ((_content.query == nil) && (_content != nil)))
	{
		@synchronized(self)
		{
			NSMutableArray <FileProviderEnumeratorObserver *> *removeObservers = [NSMutableArray new];

			for (FileProviderEnumeratorObserver *observer in _enumerationObservers)
			{
				if (observer.enumerationObserver != nil)
				{
					if (!observer.didProvideInitialItems)
					{
						NSArray <OCItem *> *queryResults = _content.query.queryResults;
						OCBookmarkUUIDString bookmarkUUIDString = _content.core.bookmark.uuid.UUIDString;

						for (OCItem *item in queryResults)
						{
							item.customIdentifier1 = bookmarkUUIDString;
							item.customIdentifier2 = _content.containerNode.itemIdentifier;
						}

						OCLogDebug(@"##### PROVIDE ITEMS TO %ld --ENUMERATION-- OBSERVER %@ FOR %@: %@", _enumerationObservers.count, observer.enumerationObserver, _content.query.queryLocation.path, queryResults);

						observer.didProvideInitialItems = YES;

						if (_content.vfsChildNodes.count > 0)
						{
							[observer.enumerationObserver didEnumerateItems:_content.vfsChildNodes];
						}

						if (queryResults.count > 0)
						{
	//							NSUInteger offset = 0, count = queryResults.count;
	//
	//							while (offset < count)
	//							{
	//								NSUInteger sliceCount = 100;
	//
	//								if (offset + sliceCount > count)
	//								{
	//									sliceCount = count - offset;
	//								}
	//
	//								NSArray<OCItem *> *partialResults = [queryResults subarrayWithRange:NSMakeRange(offset, sliceCount)];
	//
	//								[observer.enumerationObserver didEnumerateItems:partialResults];
	//
	//								offset += sliceCount;
	//							};

							[observer.enumerationObserver didEnumerateItems:queryResults];
						}

						[observer.enumerationObserver finishEnumeratingUpToPage:nil];

						[removeObservers addObject:observer];
					}
				}
			}

			[_enumerationObservers removeObjectsInArray:removeObservers];
		}
	}
}

- (void)provideItemsForChangeObserver
{
	@synchronized(self)
	{
		if (_changeObservers.count > 0)
		{
			OCLogDebug(@"##### PROVIDE ITEMS TO %lu --CHANGE-- OBSERVER FOR %@: %@", _changeObservers.count, _content.query.queryLocation.path, _content.query.queryResults);

			NSArray <OCItem *> *queryResults = _content.query.queryResults;
			OCBookmarkUUIDString bookmarkUUIDString = _content.core.bookmark.uuid.UUIDString;

			for (OCItem *item in queryResults)
			{
				item.customIdentifier1 = bookmarkUUIDString;
				item.customIdentifier2 = _content.containerNode.itemIdentifier;
			}

			NSFileProviderSyncAnchor syncAnchor = [_content.core.latestSyncAnchor syncAnchorData];

			for (FileProviderEnumeratorObserver *observer in _changeObservers)
			{
				[observer.changeObserver didUpdateItems:queryResults];
				[observer.changeObserver finishEnumeratingChangesUpToSyncAnchor:syncAnchor moreComing:NO];
			}

			[_changeObservers removeAllObjects];
		}
	}
}

- (void)queryHasChangesAvailable:(OCQuery *)query
{
	OCLogDebug(@"##### Query for %@ has changes. Query state: %lu, SinceSyncAnchor: %@, Changes available: %d", query.queryLocation.path, (unsigned long)query.state, query.querySinceSyncAnchor, query.hasChangesAvailable);

	if ( (query.state == OCQueryStateContentsFromCache) ||
	    ((query.state == OCQueryStateWaitingForServerReply) && (query.queryResults.count > 0)) ||
	     (query.state == OCQueryStateIdle))
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			@synchronized(self)
			{
				if (self->_enumerationObservers.count > 0)
				{
					[self provideItemsForEnumerationObserver];
				}

				if (self->_changeObservers.count > 0)
				{
					[self provideItemsForChangeObserver];
				}
			}
		});
	}
}

- (void)query:(OCQuery *)query failedWithError:(NSError *)error
{
	OCLogDebug(@"### Query failed with error: %@", error);
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

//		[_vfsCore provideContentForContainerItemID:_containerItemIdentifier changesFromSyncAnchor:nil completionHandler:^(NSError * _Nullable error, OCVFSContent * _Nullable content) {
//			if (error != nil)
//			{
//				[observer finishEnumeratingWithError:error];
//			}
//			else
//			{
////				[observer didEnumerateItems:content.vfsChildNodes];
////				[observer finishEnumeratingUpToPage:nil];
//			}
//		}];

		FileProviderEnumeratorObserver *enumerationObserver = [FileProviderEnumeratorObserver new];

		enumerationObserver.changeObserver = observer;
		enumerationObserver.changesFromSyncAnchor = syncAnchor;

		@synchronized(self)
		{
			[_enumerationObservers addObject:enumerationObserver];
		}

		[self _startQuery];
	}
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

+ (NSArray<OCLogTagName> *)logTags
{
	return (@[ @"FPEnum" ]);
}

- (NSArray<OCLogTagName> *)logTags
{
	return (@[ @"FPEnum", OCLogTagInstance(self)]);
}

@end
