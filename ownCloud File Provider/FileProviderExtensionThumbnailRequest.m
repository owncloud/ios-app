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

@interface FileProviderExtensionThumbnailRequest ()
{
	BOOL _isDone;
	OCResourceRequestItemThumbnail *_thumbnailRequest;
}
@end

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
			OCLocalID localID = (OCLocalID)itemIdentifier;

			// Translate item identifiers
			OCVaultLocation *location;

			if ((location = [[OCVaultLocation alloc] initWithVFSItemID:itemIdentifier]) != nil)
			{
				if (location.localID != nil)
				{
					localID = location.localID;
				}
			}

			[core retrieveItemFromDatabaseForLocalID:localID completionHandler:^(NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
				OCLogDebug(@"Retrieving %ld: %@", self.cursorPosition-1, itemFromDatabase.name);

				OCResourceManager *resourceManager = core.vault.resourceManager;

				if ((itemFromDatabase.type == OCItemTypeCollection) ||	// No previews for folders
				    (itemFromDatabase.thumbnailAvailability == OCItemThumbnailAvailabilityNone) || // No thumbnails available for this type
				    (resourceManager == nil)) // No ResourceManager available for this core
				{
					dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
						self.perThumbnailCompletionHandler(itemIdentifier, nil, nil);

						OCLogDebug(@"Replied %ld: %@ -> none available", self.cursorPosition-1, itemFromDatabase.name);

						[self requestNextThumbnail];
					});
				}
				else
				{
					OCResourceRequestItemThumbnail *thumbnailRequest = [OCResourceRequestItemThumbnail requestThumbnailFor:itemFromDatabase maximumSize:self.sizeInPixels scale:1.0 waitForConnectivity:NO changeHandler:^(OCResourceRequest * _Nonnull request, NSError * _Nullable error, BOOL isOngoing, OCResource * _Nullable previousResource, OCResource * _Nullable newResource) {

						OCLogDebug(@"Retrieved %ld: %@ -> %d", self.cursorPosition-1, itemFromDatabase.name, isOngoing);

						if (!isOngoing)
						{
							OCResourceImage *thumbnailResource = OCTypedCast(newResource, OCResourceImage);
							OCItemThumbnail *thumbnail = thumbnailResource.thumbnail;

							dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
								NSError *returnError = (thumbnail==nil) ?
												((error != nil) ? error.translatedError : OCError(OCErrorInternal)) :
												nil;

								self.perThumbnailCompletionHandler(itemIdentifier, thumbnail.data, returnError);

								OCLogDebug(@"Replied %ld: %@ -> thumbnailData=%d, error=%@", self.cursorPosition-1, itemFromDatabase.name, (thumbnail.data != nil), returnError);

								[self requestNextThumbnail];
							});
						}
					}];

					[resourceManager startRequest:thumbnailRequest];

					self->_thumbnailRequest = thumbnailRequest;
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

- (void)setProgress:(NSProgress *)progress
{
	__weak FileProviderExtensionThumbnailRequest *weakSelf = self;

	progress.cancellationHandler = ^{
		FileProviderExtensionThumbnailRequest *strongSelf;

		if ((strongSelf = weakSelf) != nil)
		{
			OCResourceRequestItemThumbnail *thumbnailRequest;

			if ((thumbnailRequest = strongSelf->_thumbnailRequest) != nil)
			{
				[strongSelf.extension.core.vault.resourceManager stopRequest:thumbnailRequest];
			}

			strongSelf->_thumbnailRequest = nil;
		}
	};
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
