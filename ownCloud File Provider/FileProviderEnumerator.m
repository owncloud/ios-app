//
//  FileProviderEnumerator.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 07.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "FileProviderEnumerator.h"
#import "FileProviderExtension.h"
#import "OCCore+FileProviderTools.h"
#import "OCItem+FileProviderItem.h"
#import "NSNumber+OCSyncAnchorData.h"

@implementation FileProviderEnumerator

@synthesize fileProviderExtension = _fileProviderExtension;

- (instancetype)initWithBookmark:(OCBookmark *)bookmark enumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier
{
	if ((self = [super init]) != nil)
	{
		_bookmark = bookmark;
		_enumeratedItemIdentifier = enumeratedItemIdentifier;

		_enumerationObservers = [NSMutableArray new];
		_changeObservers = [NSMutableArray new];
	}

	return (self);
}

- (void)invalidate
{
	OCLogDebug(@"##### INVALIDATE %@", _query.queryPath);

	if (_core != nil)
	{
		[_core stopQuery:_query];

		[[OCCoreManager sharedCoreManager] returnCoreForBookmark:_bookmark completionHandler:nil];

		_core = nil;
	}

	_query.delegate = nil;
	_query = nil;
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
		[_enumerationObservers addObject:enumerationObserver];
	}

	[self _startQuery];
}

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

- (void)_startQuery
{
	OCLogDebug(@"##### Starting query..");

	if ((_core == nil) && (_query == nil))
	{
		_core = [[OCCoreManager sharedCoreManager] requestCoreForBookmark:_bookmark completionHandler:^(OCCore *core, NSError *error) {
			self->_core = core;

			if (error != nil)
			{
				// TODO: Report error as NSFileProviderErrorServerUnreachable or NSFileProviderErrorNotAuthenticated, depending on what the underlying error is
				[self _finishAllEnumeratorsWithError:error];
			}
			else
			{
				// Create and add query
				__block OCPath queryPath = nil;

				if ([self->_enumeratedItemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
				{
					queryPath = @"/";
				}
				else
				{
					NSError *error = nil;
					OCItem *item;

					if ((item = [core synchronousRetrieveItemFromDatabaseForFileID:self->_enumeratedItemIdentifier syncAnchor:NULL error:&error]) != nil)
					{
						if (item.type == OCItemTypeCollection)
						{
							queryPath = item.path;
						}
//
//						if (item.type == OCItemTypeFile)
//						{
//							OCLogDebug(@"Observe item: %@", item);
//
//							[observer didEnumerateItems:@[ item ]];
//							[observer finishEnumeratingUpToPage:nil];
//							return;
//						}
					}
				}

				if (queryPath == nil)
				{
					// Item not found or not a directory
					NSError *enumerationError = [NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorNoSuchItem userInfo:nil];

					[self _finishAllEnumeratorsWithError:enumerationError];
					return;
				}
				else
				{
					// Start query
					self->_query = [OCQuery queryForPath:queryPath];
					self->_query.delegate = self;

					@synchronized(self)
					{
						if ([self->_enumerationObservers.lastObject.enumerationStartPage isEqual:NSFileProviderInitialPageSortedByDate])
						{
							self->_query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
								return ([item1.lastModified compare:item2.lastModified]);
							};
						}

						if ([self->_enumerationObservers.lastObject.enumerationStartPage isEqual:NSFileProviderInitialPageSortedByName])
						{
							self->_query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
								return ([item1.name compare:item2.name]);
							};
						}
					}

					OCLogDebug(@"##### START QUERY FOR %@", self->_query.queryPath);

					[core startQuery:self->_query];
				}
			}
		}];
	}
	else
	{
		OCLogDebug(@"Query already running..");

		if (_query != nil)
		{
			@synchronized(self)
			{
				if (_enumerationObservers.count!=0)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self provideItemsForEnumerationObserverFromQuery:self->_query];
					});
				}

				if (_changeObservers.count!=0)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self provideItemsForChangeObserverFromQuery:self->_query];
					});
				}
			}
		}
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

- (void)provideItemsForEnumerationObserverFromQuery:(OCQuery *)query
{
	if ((query.state == OCQueryStateContentsFromCache) || ((query.state == OCQueryStateWaitingForServerReply) && (query.queryResults.count > 0)) || (query.state == OCQueryStateIdle))
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
						OCLogDebug(@"##### PROVIDE ITEMS TO %ld --ENUMERATION-- OBSERVER %@ FOR %@: %@", _enumerationObservers.count, observer.enumerationObserver, query.queryPath, query.queryResults);

						observer.didProvideInitialItems = YES;

						if (query.queryResults != nil)
						{
							[observer.enumerationObserver didEnumerateItems:query.queryResults];
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

- (void)provideItemsForChangeObserverFromQuery:(OCQuery *)query
{
	@synchronized(self)
	{
		if (_changeObservers.count > 0)
		{
			OCLogDebug(@"##### PROVIDE ITEMS TO %d --CHANGE-- OBSERVER FOR %@: %@", _changeObservers.count, query.queryPath, query.queryResults);

			for (FileProviderEnumeratorObserver *observer in _changeObservers)
			{
				[observer.changeObserver didUpdateItems:query.queryResults];
				[observer.changeObserver finishEnumeratingChangesUpToSyncAnchor:[_core.latestSyncAnchor syncAnchorData] moreComing:NO];
			}

			[_changeObservers removeAllObjects];
		}
	}
}

- (void)queryHasChangesAvailable:(OCQuery *)query
{
	OCLogDebug(@"##### Query for %@ has changes. Query state: %lu", query.queryPath, (unsigned long)query.state);

	if ((query.state == OCQueryStateContentsFromCache) || ((query.state == OCQueryStateWaitingForServerReply) && (query.queryResults.count > 0)) || (query.state == OCQueryStateIdle))
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			@synchronized(self)
			{
				if (self->_enumerationObservers.count > 0)
				{
					[self provideItemsForEnumerationObserverFromQuery:query];
				}

				if (self->_changeObservers.count > 0)
				{
					[self provideItemsForChangeObserverFromQuery:query];
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
			if ([syncAnchor isEqual:[self->_core.latestSyncAnchor syncAnchorData]])
			{
				OCLogDebug(@"##### END(LATEST) Enumerate CHANGES for observer: %@ fromSyncAnchor: %@", observer, syncAnchor);
				[observer finishEnumeratingChangesUpToSyncAnchor:syncAnchor moreComing:NO];
			}
			else
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

- (void)currentSyncAnchorWithCompletionHandler:(void (^)(NSFileProviderSyncAnchor _Nullable))completionHandler
{
	OCLogDebug(@"#### Request current sync anchor");

	dispatch_async(dispatch_get_main_queue(), ^{
		completionHandler([self->_core.latestSyncAnchor syncAnchorData]);
	});
}

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

@end
