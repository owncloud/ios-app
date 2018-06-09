//
//  FileProviderExtensionThumbnailRequest.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import "FileProviderExtensionThumbnailRequest.h"

@implementation FileProviderExtensionThumbnailRequest

- (void)dealloc
{
	NSLog(@"Dealloc %@", self);
}

- (void)requestNextThumbnail
{
	if (_isDone)
	{
		return;
	}

	if (self.progress.cancelled)
	{
		_isDone = YES;
		return;
	}

	if (self.cursorPosition < self.itemIdentifiers.count)
	{
		NSFileProviderItemIdentifier itemIdentifier = self.itemIdentifiers[self.cursorPosition];

		NSLog(@"Retrieving %ld / %ld:", self.cursorPosition, self.itemIdentifiers.count);

		self.cursorPosition += 1;

		[self.extension.core retrieveItemFromDatabaseForFileID:(OCFileID)itemIdentifier completionHandler:^(NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
			NSLog(@"Retrieving %ld: %@", self.cursorPosition-1, itemFromDatabase.name);

			if ((itemFromDatabase.type == OCItemTypeCollection) || (itemFromDatabase.thumbnailAvailability == OCItemThumbnailAvailabilityNone))
			{
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
					self.perThumbnailCompletionHandler(itemIdentifier, nil, nil);

					NSLog(@"Replied %ld: %@ -> none available", self.cursorPosition-1, itemFromDatabase.name);

					[self requestNextThumbnail];
				});
			}
			else
			{
				NSProgress *retrieveProgress = [self.extension.core retrieveThumbnailFor:itemFromDatabase maximumSize:self.sizeInPixels scale:1.0 retrieveHandler:^(NSError *error, OCCore *core, OCItem *item, OCItemThumbnail *thumbnail, BOOL isOngoing, NSProgress *progress) {

					NSLog(@"Retrieved %ld: %@ -> %d", self.cursorPosition-1, itemFromDatabase.name, isOngoing);

					if (!isOngoing)
					{
						dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
							self.perThumbnailCompletionHandler(itemIdentifier, thumbnail.data, error);

							[self requestNextThumbnail];
						});
					}
				}];

				[self.progress addChild:retrieveProgress withPendingUnitCount:1];
			}
		}];
	}
	else
	{
		NSLog(@"Done retrieving %ld / %ld", self.cursorPosition, self.itemIdentifiers.count);

		_isDone = YES;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.completionHandler(nil);
		});
	}

	/*
	dispatch_group_t allThumbnailsFetchedGroup = dispatch_group_create();
	NSProgress *fetchThumbnailsProgress = [NSProgress indeterminateProgress];

	for (NSFileProviderItemIdentifier itemIdentifier in itemIdentifiers)
	{
		dispatch_group_enter(allThumbnailsFetchedGroup);

		[_core retrieveItemFromDatabaseForFileID:(OCFileID)itemIdentifier completionHandler:^(NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
			if (itemFromDatabase.type == OCItemTypeCollection)
			{
				perThumbnailCompletionHandler(itemIdentifier, nil, nil);

				dispatch_group_leave(allThumbnailsFetchedGroup);
			}
			else
			{
				[_core retrieveThumbnailFor:itemFromDatabase maximumSize:size scale:0 retrieveHandler:^(NSError *error, OCCore *core, OCItem *item, OCItemThumbnail *thumbnail, BOOL isOngoing, NSProgress *progress) {
					[fetchThumbnailsProgress addChild:progress withPendingUnitCount:0];

					if (!isOngoing)
					{
						perThumbnailCompletionHandler(itemIdentifier, thumbnail.data, error);

						dispatch_group_leave(allThumbnailsFetchedGroup);
					}
				}];
			}
		}];
	}

	dispatch_group_notify(allThumbnailsFetchedGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		completionHandler(nil);
	});

	return (fetchThumbnailsProgress);
	*/
}

@end
