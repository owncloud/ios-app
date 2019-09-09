//
//  FileProviderExtensionThumbnailRequest.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
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

#import "FileProviderExtensionThumbnailRequest.h"
#import "NSError+MessageResolution.h"

@implementation FileProviderExtensionThumbnailRequest

- (void)dealloc
{
	OCLogDebug(@"Dealloc %@", self);
}

- (void)requestNextThumbnail
{
	if (_isDone)
	{
		return;
	}

	if (self.progress.cancelled)
	{
		OCLogDebug(@"Thumbnail request cancelled by the system");
		[self completedRequestWithError:nil];
		return;
	}

	if (self.cursorPosition < self.itemIdentifiers.count)
	{
		NSFileProviderItemIdentifier itemIdentifier = self.itemIdentifiers[self.cursorPosition];

		OCLogDebug(@"Retrieving %ld / %ld:", self.cursorPosition, self.itemIdentifiers.count);

		self.cursorPosition += 1;

		OCCore *core;

		if ((core = self.extension.core) != nil)
		{
//			if (core.connectionStatus == OCCoreConnectionStatusOnline)
			[core retrieveItemFromDatabaseForLocalID:(OCLocalID)itemIdentifier completionHandler:^(NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
				OCLogDebug(@"Retrieving %ld: %@", self.cursorPosition-1, itemFromDatabase.name);

				if ((itemFromDatabase.type == OCItemTypeCollection) || (itemFromDatabase.thumbnailAvailability == OCItemThumbnailAvailabilityNone))
				{
					dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
						self.perThumbnailCompletionHandler(itemIdentifier, nil, nil);

						OCLogDebug(@"Replied %ld: %@ -> none available", self.cursorPosition-1, itemFromDatabase.name);

						[self requestNextThumbnail];
					});
				}
				else
				{
					NSProgress *retrieveProgress = [self.extension.core retrieveThumbnailFor:itemFromDatabase maximumSize:self.sizeInPixels scale:1.0 waitForConnectivity:NO retrieveHandler:^(NSError *error, OCCore *core, OCItem *item, OCItemThumbnail *thumbnail, BOOL isOngoing, NSProgress *progress) {

						OCLogDebug(@"Retrieved %ld: %@ -> %d", self.cursorPosition-1, itemFromDatabase.name, isOngoing);

						if (!isOngoing)
						{
							dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
								self.perThumbnailCompletionHandler(itemIdentifier, thumbnail.data, (thumbnail==nil) ? nil : [error resolvedError]);

								OCLogDebug(@"Replied %ld: %@ -> thumbnailData=%d, error=%@", self.cursorPosition-1, itemFromDatabase.name, (thumbnail.data != nil), error);

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
			OCLogDebug(@"Stopping thumbnail retrieval due to lack of core");
			[self completedRequestWithError:OCError(OCErrorInternal)];
		}
	}
	else
	{
		OCLogDebug(@"Done retrieving %ld / %ld", self.cursorPosition, self.itemIdentifiers.count);

		[self completedRequestWithError:nil];
	}
}

- (void)completedRequestWithError:(NSError *)error
{
	if (!_isDone)
	{
		_isDone = YES;

		dispatch_async(dispatch_get_main_queue(), ^{
			self.completionHandler(nil);
		});
	}
}

- (nonnull NSArray<OCLogTagName> *)logTags
{
	return (@[@"FPThumbs"]);
}

+ (nonnull NSArray<OCLogTagName> *)logTags
{
	return (@[@"FPThumbs"]);
}

@end
