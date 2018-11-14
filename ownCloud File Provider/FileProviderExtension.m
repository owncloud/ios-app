//
//  FileProviderExtension.m
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

#import <ownCloudSDK/ownCloudSDK.h>

#import "FileProviderExtension.h"
#import "FileProviderEnumerator.h"
#import "OCItem+FileProviderItem.h"
#import "FileProviderExtensionThumbnailRequest.h"

@interface FileProviderExtension ()

@property (nonatomic, readonly, strong) NSFileManager *fileManager;

@end

@implementation FileProviderExtension

@synthesize core;
@synthesize bookmark;

- (instancetype)init
{
	NSDictionary *bundleInfoDict = [[NSBundle bundleForClass:[FileProviderExtension class]] infoDictionary];

	OCCore.hostHasFileProvider = YES;

	OCAppIdentity.sharedAppIdentity.appIdentifierPrefix = bundleInfoDict[@"OCAppIdentifierPrefix"];
	OCAppIdentity.sharedAppIdentity.keychainAccessGroupIdentifier = bundleInfoDict[@"OCKeychainAccessGroupIdentifier"];
	OCAppIdentity.sharedAppIdentity.appGroupIdentifier = bundleInfoDict[@"OCAppGroupIdentifier"];

	if (self = [super init]) {
		_fileManager = [[NSFileManager alloc] init];
	}

	return self;
}

- (void)dealloc
{
	if (_core != nil)
	{
		[[OCCoreManager sharedCoreManager] returnCoreForBookmark:self.bookmark completionHandler:nil];
	}
}

#pragma mark - ItemIdentifier & URL lookup
- (NSFileProviderItem)itemForIdentifier:(NSFileProviderItemIdentifier)identifier error:(NSError *__autoreleasing  _Nullable *)outError
{
	__block NSFileProviderItem item = nil;
	__block NSError *returnError = nil;

	OCSyncExec(itemRetrieval, {
		// Resolve the given identifier to a record in the model
		if ([identifier isEqual:NSFileProviderRootContainerItemIdentifier])
		{
			// Root item
			[self.core.vault.database retrieveCacheItemsAtPath:@"/" itemOnly:YES completionHandler:^(OCDatabase *db, NSError *error, OCSyncAnchor syncAnchor, NSArray<OCItem *> *items) {
				item = items.firstObject;

				returnError = error;

				OCSyncExecDone(itemRetrieval);
			}];
		}
		else
		{
			// Other item
			[self.core retrieveItemFromDatabaseForFileID:(OCFileID)identifier completionHandler:^(NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
				item = itemFromDatabase;
				returnError = error;

				OCSyncExecDone(itemRetrieval);
			}];
		}
	});

	OCLogDebug(@"-itemForIdentifier:error: %@ => %@", identifier, item);

	if ((item == nil) && (returnError == nil))
	{
		returnError = [NSError fileProviderErrorForNonExistentItemWithIdentifier:identifier];
	}

	if (outError != NULL)
	{
		*outError = returnError;
	}

	return item;
}

- (NSURL *)URLForItemWithPersistentIdentifier:(NSFileProviderItemIdentifier)identifier
{
	OCItem *item;
	NSURL *url = nil;

	if ((item = (OCItem *)[self itemForIdentifier:identifier error:NULL]) != nil)
	{
		url = [self.core localURLForItem:item];
	}

	OCLogDebug(@"-URLForItemWithPersistentIdentifier: %@ => %@", identifier, url);

	return (url);

	/*
	// resolve the given identifier to a file on disk

	// in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
	NSFileProviderManager *manager = [NSFileProviderManager defaultManager];
	NSURL *perItemDirectory = [manager.documentStorageURL URLByAppendingPathComponent:identifier isDirectory:YES];

	return [perItemDirectory URLByAppendingPathComponent:item.filename isDirectory:NO];
	*/
}

- (NSFileProviderItemIdentifier)persistentIdentifierForItemAtURL:(NSURL *)url
{
	// resolve the given URL to a persistent identifier using a database
	NSArray <NSString *> *pathComponents = [url pathComponents];

	// exploit the fact that the path structure has been defined as
	// <base storage directory>/<item identifier>/<item file name> above
	NSParameterAssert(pathComponents.count > 2);

	OCLogDebug(@"-persistentIdentifierForItemAtURL: %@", (pathComponents[pathComponents.count - 2]));

	return pathComponents[pathComponents.count - 2];
}

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
	NSFileProviderItemIdentifier identifier = [self persistentIdentifierForItemAtURL:url];
	if (!identifier) {
		completionHandler([NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorNoSuchItem userInfo:nil]);
		return;
	}

	NSError *error = nil;
	NSFileProviderItem fileProviderItem = [self itemForIdentifier:identifier error:&error];
	if (!fileProviderItem) {
		completionHandler(error);
		return;
	}
	NSURL *placeholderURL = [NSFileProviderManager placeholderURLForURL:url];

	[[NSFileManager defaultManager] createDirectoryAtURL:url.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];

	if (![NSFileProviderManager writePlaceholderAtURL:placeholderURL withMetadata:fileProviderItem error:&error]) {
		completionHandler(error);
		return;
	}
	completionHandler(nil);
}

- (void)startProvidingItemAtURL:(NSURL *)provideAtURL completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	NSFileProviderItemIdentifier itemIdentifier = nil;
	NSFileProviderItem item = nil;

	if ((itemIdentifier = [self persistentIdentifierForItemAtURL:provideAtURL]) != nil)
	{
		 if ((item = [self itemForIdentifier:itemIdentifier error:&error]) != nil)
		 {
			[self.core downloadItem:(OCItem *)item options:nil resultHandler:^(NSError *error, OCCore *core, OCItem *item, OCFile *file) {
				OCLogDebug(@"Starting to provide file:\nPAU: %@\nFURL: %@\nID: %@\nErr: %@\nlocalRelativePath: %@", provideAtURL, file.url, item.itemIdentifier, error, item.localRelativePath);

				completionHandler(error);
			}];

			return;
		 }
	}

	completionHandler([NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{}]);

	// ### Apple template comments: ###

	// Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler

	/* TODO:
	 This is one of the main entry points of the file provider. We need to check whether the file already exists on disk,
	 whether we know of a more recent version of the file, and implement a policy for these cases. Pseudocode:

	 if (!fileOnDisk) {
	 downloadRemoteFile();
	 callCompletion(downloadErrorOrNil);
	 } else if (fileIsCurrent) {
	 callCompletion(nil);
	 } else {
	 if (localFileHasChanges) {
	 // in this case, a version of the file is on disk, but we know of a more recent version
	 // we need to implement a strategy to resolve this conflict
	 moveLocalFileAside();
	 scheduleUploadOfLocalFile();
	 downloadRemoteFile();
	 callCompletion(downloadErrorOrNil);
	 } else {
	 downloadRemoteFile();
	 callCompletion(downloadErrorOrNil);
	 }
	 }
	 */
}


- (void)itemChangedAtURL:(NSURL *)changedItemURL
{
	NSError *error = nil;
	NSFileProviderItemIdentifier itemIdentifier = nil;
	NSFileProviderItem item = nil, parentItem = nil;

	if ((itemIdentifier = [self persistentIdentifierForItemAtURL:changedItemURL]) != nil)
	{
		 if ((item = [self itemForIdentifier:itemIdentifier error:&error]) != nil)
		 {
			if ((parentItem = [self itemForIdentifier:item.parentItemIdentifier error:&error]) != nil)
			{
				[self.core reportLocalModificationOfItem:(OCItem *)item parentItem:(OCItem *)parentItem withContentsOfFileAtURL:changedItemURL isSecurityScoped:NO options:nil placeholderCompletionHandler:nil resultHandler:^(NSError *error, OCCore *core, OCItem *item, id parameter) {
					OCLogDebug(@"Upload of update finished with error=%@ item=%@", error, item);
				}];
			}
		 }
	}

	// ### Apple template comments: ###

	// Called at some point after the file has changed; the provider may then trigger an upload

	/* TODO:
	 - mark file at <url> as needing an update in the model
	 - if there are existing NSURLSessionTasks uploading this file, cancel them
	 - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
	 - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
	 */
}

- (void)stopProvidingItemAtURL:(NSURL *)url
{
	// ### Apple template comments: ###

	// Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.

	// TODO: look up whether the file has local changes
	//	BOOL fileHasLocalChanges = NO;
	//
	//	if (!fileHasLocalChanges) {
	//		// remove the existing file to free up space
	//		[[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
	//
	//		// write out a placeholder to facilitate future property lookups
	//		[self providePlaceholderAtURL:url completionHandler:^(NSError * __nullable error) {
	//			// TODO: handle any error, do any necessary cleanup
	//		}];
	//	}
}

#pragma mark - Actions

// ### Apple template comments: ###

/* TODO: implement the actions for items here
 each of the actions follows the same pattern:
 - make a note of the change in the local model
 - schedule a server request as a background task to inform the server of the change
 - call the completion block with the modified item in its post-modification state
 */

- (void)createDirectoryWithName:(NSString *)directoryName inParentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	OCItem *parentItem;

	if ((parentItem = (OCItem *)[self itemForIdentifier:parentItemIdentifier error:&error]) != nil)
	{
		[self.core createFolder:directoryName inside:parentItem options:nil resultHandler:^(NSError *error, OCCore *core, OCItem *item, id parameter) {
			completionHandler(item, error);
		}];
	}
	else
	{
		completionHandler(nil, error);
	}
}

- (void)reparentItemWithIdentifier:(NSFileProviderItemIdentifier)itemIdentifier toParentItemWithIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier newName:(NSString *)newName completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	OCItem *item, *parentItem;

	if (((item = (OCItem *)[self itemForIdentifier:itemIdentifier error:&error]) != nil) &&
	    ((parentItem = (OCItem *)[self itemForIdentifier:parentItemIdentifier error:&error]) != nil))
	{
		[self.core moveItem:item to:parentItem withName:((newName != nil) ? newName : item.name) options:nil resultHandler:^(NSError *error, OCCore *core, OCItem *item, id parameter) {
			completionHandler(item, error);
		}];
	}
	else
	{
		completionHandler(nil, error);
	}
}

- (void)renameItemWithIdentifier:(NSFileProviderItemIdentifier)itemIdentifier toName:(NSString *)itemName completionHandler:(void (^)(NSFileProviderItem renamedItem, NSError *error))completionHandler
{
	NSError *error = nil;
	OCItem *item, *parentItem;

	if (((item = (OCItem *)[self itemForIdentifier:itemIdentifier error:&error]) != nil) &&
	    ((parentItem = (OCItem *)[self itemForIdentifier:item.parentFileID error:&error]) != nil))
	{
		[self.core moveItem:item to:parentItem withName:itemName options:nil resultHandler:^(NSError *error, OCCore *core, OCItem *item, id parameter) {
			completionHandler(item, error);
		}];
	}
	else
	{
		completionHandler(nil, error);
	}
}

- (void)trashItemWithIdentifier:(NSFileProviderItemIdentifier)itemIdentifier completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	OCItem *item;

	if ((item = (OCItem *)[self itemForIdentifier:itemIdentifier error:&error]) != nil)
	{
		[self.core deleteItem:item requireMatch:YES resultHandler:^(NSError *error, OCCore *core, OCItem *item, id parameter) {
			completionHandler(nil, error);
		}];
	}
	else
	{
		completionHandler(nil, error);
	}
}

- (void)deleteItemWithIdentifier:(NSFileProviderItemIdentifier)itemIdentifier completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	OCItem *item;

	if ((item = (OCItem *)[self itemForIdentifier:itemIdentifier error:&error]) != nil)
	{
		[self.core deleteItem:item requireMatch:YES resultHandler:^(NSError *error, OCCore *core, OCItem *item, id parameter) {
			completionHandler(error);
		}];
	}
	else
	{
		completionHandler(error);
	}
}

- (void)importDocumentAtURL:(NSURL *)fileURL toParentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	BOOL isImportingFromVault = NO;
	BOOL importByCopying = NO;
	NSString *importFileName = fileURL.lastPathComponent;
	OCItem *parentItem;

	// Detect import of documents from our own internal storage (=> used by Files.app for duplication of files)
	isImportingFromVault = [fileURL.path hasPrefix:self.core.vault.filesRootURL.path];

	if (isImportingFromVault)
	{
		NSFileProviderItemIdentifier sourceItemIdentifier;
		NSFileProviderItem sourceItem;

		// Determine source item
		if (((sourceItemIdentifier = [self persistentIdentifierForItemAtURL:fileURL]) != nil) &&
		    ((sourceItem = [self itemForIdentifier:sourceItemIdentifier error:nil]) != nil))
		{
			importByCopying = YES;
		}
	}

	if ((parentItem = (OCItem *)[self itemForIdentifier:parentItemIdentifier error:&error]) != nil)
	{
		// Detect name collissions
		OCPath parentPath;

		if (((parentPath = parentItem.path) != nil) && (importFileName != nil))
		{
			OCPath destinationPath = [parentPath stringByAppendingPathComponent:importFileName];
			__block OCItem *existingItem = nil;

			OCSyncExec(retrieveExistingItem, {
				[self.core.vault.database retrieveCacheItemsAtPath:destinationPath itemOnly:YES completionHandler:^(OCDatabase *db, NSError *error, OCSyncAnchor syncAnchor, NSArray<OCItem *> *items) {
					existingItem = items.firstObject;
					OCSyncExecDone(retrieveExistingItem);
				}];
			});

			if (existingItem != nil)
			{
				// Return collission error
				completionHandler(nil, [NSError fileProviderErrorForCollisionWithItem:existingItem]);
				return;
			}
		}

		// Start import
		[self.core importFileNamed:importFileName at:parentItem fromURL:fileURL isSecurityScoped:YES options:@{ OCCoreOptionImportByCopying : @(importByCopying) } placeholderCompletionHandler:^(NSError *error, OCItem *item) {
			completionHandler(item, error);
		} resultHandler:nil];
	}
	else
	{
		completionHandler(nil, error);
	}
}

- (void)setFavoriteRank:(NSNumber *)favoriteRank forItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	OCItem *item;

	if ((item = (OCItem *)[self itemForIdentifier:itemIdentifier error:&error]) != nil)
	{
		[item setLocalFavoriteRank:favoriteRank];

		[self.core performUpdatesForAddedItems:nil removedItems:nil updatedItems:@[ item ] refreshPaths:nil newSyncAnchor:nil preflightAction:nil postflightAction:^(dispatch_block_t  _Nonnull postFlightCompletionHandler) {
			completionHandler(item, nil);
			postFlightCompletionHandler();
		} queryPostProcessor:nil];
	}
	else
	{
		completionHandler(nil, error);
	}
}

- (void)setTagData:(NSData *)tagData forItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
	NSError *error = nil;
	OCItem *item;

//	// Example of self-creating tagData
//	tagData = [NSKeyedArchiver archivedDataWithRootObject:@{
//		@"t" : @[
//			@[ @"Root", @(6) ],	// First value is the label, second a color number
//			@[ @"Beer", @(4) ],
//		],
//
//		@"v" : @(1)	// Version (?)
//	}];

	if ((item = (OCItem *)[self itemForIdentifier:itemIdentifier error:&error]) != nil)
	{
		[item setLocalTagData:tagData];

		[self.core performUpdatesForAddedItems:nil removedItems:nil updatedItems:@[ item ] refreshPaths:nil newSyncAnchor:nil preflightAction:nil postflightAction:^(dispatch_block_t  _Nonnull postFlightCompletionHandler) {
			completionHandler(item, nil);
			postFlightCompletionHandler();
		} queryPostProcessor:nil];
	}
	else
	{
		completionHandler(nil, error);
	}
}

#pragma mark - Enumeration

- (nullable id<NSFileProviderEnumerator>)enumeratorForContainerItemIdentifier:(NSFileProviderItemIdentifier)containerItemIdentifier error:(NSError **)error
{
	if (self.domain.identifier == nil)
	{
		if (error != NULL)
		{
			*error = [NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorNotAuthenticated userInfo:nil];
		}

		return (nil);
	}

	if (![containerItemIdentifier isEqualToString:NSFileProviderWorkingSetContainerItemIdentifier])
	{
		FileProviderEnumerator *enumerator = [[FileProviderEnumerator alloc] initWithBookmark:self.bookmark enumeratedItemIdentifier:containerItemIdentifier];

		enumerator.fileProviderExtension = self;

		return (enumerator);
	}

	return (nil);

	// ### Apple template comments: ###

	/*
	FileProviderEnumerator *enumerator = nil;

	if ([containerItemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier]) {
		// TODO: instantiate an enumerator for the container root
	} else if ([containerItemIdentifier isEqualToString:NSFileProviderWorkingSetContainerItemIdentifier]) {
		// TODO: instantiate an enumerator for the working set
	} else {
		// TODO: determine if the item is a directory or a file
		// - for a directory, instantiate an enumerator of its subitems
		// - for a file, instantiate an enumerator that observes changes to the file
	}

	return enumerator;
	*/
}

#pragma mark - Thumbnails
- (NSProgress *)fetchThumbnailsForItemIdentifiers:(NSArray<NSFileProviderItemIdentifier> *)itemIdentifiers requestedSize:(CGSize)size perThumbnailCompletionHandler:(void (^)(NSFileProviderItemIdentifier _Nonnull, NSData * _Nullable, NSError * _Nullable))perThumbnailCompletionHandler completionHandler:(void (^)(NSError * _Nullable))completionHandler
{
	FileProviderExtensionThumbnailRequest *thumbnailRequest;

	if ((thumbnailRequest = [FileProviderExtensionThumbnailRequest new]) != nil)
	{
		if (size.width > 256)
		{
			size.width = 256;
		}

		if (size.height > 256)
		{
			size.height = 256;
		}

		thumbnailRequest.extension = self;
		thumbnailRequest.itemIdentifiers = itemIdentifiers;
		thumbnailRequest.sizeInPixels = size;
		thumbnailRequest.perThumbnailCompletionHandler = perThumbnailCompletionHandler;
		thumbnailRequest.completionHandler = completionHandler;
		thumbnailRequest.progress = [NSProgress progressWithTotalUnitCount:itemIdentifiers.count];

		[thumbnailRequest requestNextThumbnail];
	}

	return (thumbnailRequest.progress);
}

#pragma mark - Core
- (OCBookmark *)bookmark
{
	@synchronized(self)
	{
		if (_bookmark == nil)
		{
			NSFileProviderDomainIdentifier domainIdentifier;

			if ((domainIdentifier = self.domain.identifier) != nil)
			{
				NSUUID *bookmarkUUID = [[NSUUID alloc] initWithUUIDString:domainIdentifier];

				_bookmark = [[OCBookmarkManager sharedBookmarkManager] bookmarkForUUID:bookmarkUUID];

				if (_bookmark == nil)
				{
					OCLogError(@"Error retrieving bookmark for domain %@ (UUID %@) - reloading", OCLogPrivate(self.domain.displayName), OCLogPrivate(self.domain.identifier));

					[[OCBookmarkManager sharedBookmarkManager] loadBookmarks];

					_bookmark = [[OCBookmarkManager sharedBookmarkManager] bookmarkForUUID:bookmarkUUID];

					if (_bookmark == nil)
					{
						OCLogError(@"Error retrieving bookmark for domain %@ (UUID %@) - final", OCLogPrivate(self.domain.displayName), OCLogPrivate(self.domain.identifier));
					}
				}
			}
		}
	}

	return (_bookmark);
}

- (OCCore *)core
{
	@synchronized(self)
	{
		if (_core == nil)
		{
			if (self.bookmark != nil)
			{
				OCSyncExec(waitForCore, {
					_core = [[OCCoreManager sharedCoreManager] requestCoreForBookmark:self.bookmark completionHandler:^(OCCore *core, NSError *error) {
						OCSyncExecDone(waitForCore);
					}];
				});

				_core.delegate = self;
			}
		}

		if (_core == nil)
		{
			OCLogError(@"Error getting core for domain %@ (UUID %@)", OCLogPrivate(self.domain.displayName), OCLogPrivate(self.domain.identifier));
		}
	}

	return (_core);
}

- (void)core:(OCCore *)core handleError:(NSError *)error issue:(OCConnectionIssue *)issue
{
	OCLogDebug(@"CORE ERROR: error=%@, issue=%@", error, issue);

	if (issue.type == OCConnectionIssueTypeMultipleChoice)
	{
		[issue cancel];
	}
}

@end

