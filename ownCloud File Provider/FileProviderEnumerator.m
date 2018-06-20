//
//  FileProviderEnumerator.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 07.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import "FileProviderEnumerator.h"
#import "OCCore+FileProviderTools.h"
#import "OCItem+FileProviderItem.h"

@implementation FileProviderEnumerator

- (instancetype)initWithBookmark:(OCBookmark *)bookmark enumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier
{
	if ((self = [super init]) != nil)
	{
		_bookmark = bookmark;
		_enumeratedItemIdentifier = enumeratedItemIdentifier;
	}

	return (self);
}

- (void)invalidate
{
	NSLog(@"##### INVALIDATE %@", _query.queryPath);

	if (_core != nil)
	{
		[_core stopQuery:_query];
		[[OCCoreManager sharedCoreManager] returnCoreForBookmark:_bookmark completionHandler:nil];

		_core = nil;
	}

	_query = nil;
}

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
	if ((_core == nil) && (_query == nil))
	{
		_core = [[OCCoreManager sharedCoreManager] requestCoreForBookmark:_bookmark completionHandler:^(OCCore *core, NSError *error) {
			_core = core;

			if (error != nil)
			{
				// TODO: Report error as NSFileProviderErrorServerUnreachable or NSFileProviderErrorNotAuthenticated, depending on what the underlying error is
				[observer finishEnumeratingWithError:error];
			}
			else
			{
				// Create and add query
				__block OCPath queryPath = nil;

				if ([_enumeratedItemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
				{
					queryPath = @"/";
				}
				else
				{
					NSError *error = nil;
					OCItem *item;

					if ((item = [core synchronousRetrieveItemFromDatabaseForFileID:_enumeratedItemIdentifier syncAnchor:NULL error:&error]) != nil)
					{
						if (item.type == OCItemTypeCollection)
						{
							queryPath = item.path;
						}
					}
				}

				if (queryPath == nil)
				{
					// Item not found or not a directory
					[observer finishEnumeratingWithError:[NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorNoSuchItem userInfo:nil]];
					return;
				}
				else
				{
					// Start query
					_query = [OCQuery queryForPath:queryPath];

					if ([page isEqual:NSFileProviderInitialPageSortedByDate])
					{
						_query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
							return ([item1.lastModified compare:item2.lastModified]);
						};
					}

					if ([page isEqual:NSFileProviderInitialPageSortedByName])
					{
						_query.sortComparator = ^NSComparisonResult(OCItem *item1, OCItem *item2) {
							return ([item1.name compare:item2.name]);
						};
					}

					_query.changesAvailableNotificationHandler = ^(OCQuery *query) {
						// TODO: Find way to best represent the "from cache" stage. Right now, skipping it altogether.

						if (_query.state == OCQueryStateIdle)
						{
							dispatch_async(dispatch_get_main_queue(), ^{
								NSLog(@"##### DELIVER RESULTS TO %@", query.queryPath);
								if (query.queryResults != nil)
								{
									[observer didEnumerateItems:query.queryResults];
								}

								[observer finishEnumeratingUpToPage:nil];
							});
						}
					};

					NSLog(@"##### START QUERY FOR %@", _query.queryPath);

					[core startQuery:_query];
				}
			}
		}];
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
