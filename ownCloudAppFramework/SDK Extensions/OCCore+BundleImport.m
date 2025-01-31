//
//  OCCore+BundleImport.m
//  ownCloud
//
//  Created by Felix Schwarz on 02.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCCore+BundleImport.h"
#import "NSURL+OCVaultTools.h"

@implementation OCCore (BundleImport)

- (nullable NSProgress *)importItemNamed:(nullable NSString *)newFileName at:(OCItem *)parentItem fromURL:(NSURL *)inputFileURL isSecurityScoped:(BOOL)isSecurityScoped options:(nullable NSDictionary<OCCoreOption,id> *)inOptions placeholderCompletionHandler:(nullable OCCorePlaceholderCompletionHandler)placeholderCompletionHandler resultHandler:(nullable OCCoreUploadResultHandler)resultHandler
{
	NSMutableDictionary<OCCoreOption,id> *options = (inOptions != nil) ? [inOptions mutableCopy] : [NSMutableDictionary new];
	__block NSProgress *progress = nil;

	// Make copy of the input file on import (lightweight/almost no storage overhead when using APFS storage)
	options[OCCoreOptionImportByCopying] = @(YES);

	if (inputFileURL.isLocatedWithinVaultStorage)
	{
		// Import from URL inside vault storage ("our" storage)
		progress = [self importFileNamed:newFileName at:parentItem fromURL:inputFileURL isSecurityScoped:NO options:options placeholderCompletionHandler:placeholderCompletionHandler resultHandler:resultHandler];
	}
	else
	{
		NSError *error = nil;

		// Import from URL outside vault storage
		if (inputFileURL.isLocalFile)
		{
			// Import of file => direct import possible
			progress = [self importFileNamed:newFileName at:parentItem fromURL:inputFileURL isSecurityScoped:isSecurityScoped options:options placeholderCompletionHandler:placeholderCompletionHandler resultHandler:resultHandler];
		}
		else
		{
			// Import of non-file (f.ex. Pages/Keynote bundle format (folders in the file system)) => access through file coordinator
			BOOL relinquishSecurityScopedResourceAccess = NO;

			if (isSecurityScoped)
			{
				relinquishSecurityScopedResourceAccess = [inputFileURL startAccessingSecurityScopedResource];
			}

			// Using NSFileCoordinatior with "NSFileCoordinatorReadingForUploading" transparently converts bundle-based formats like f.ex. Keynote and Pages documents to flat files
			NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
			[fileCoordinator coordinateReadingItemAtURL:inputFileURL options:NSFileCoordinatorReadingWithoutChanges|NSFileCoordinatorReadingForUploading error:&error byAccessor:^(NSURL * _Nonnull importURL) {
				OCLogDebug(@"Coordinated read of readURL=%@, attributes=%@", importURL, [NSFileManager.defaultManager attributesOfItemAtPath:importURL.path error:nil]);

				// File pointed to by importURL may be ephermal and copies are "free" in APFS as far as space is concerned
				progress = [self importFileNamed:newFileName at:parentItem fromURL:importURL isSecurityScoped:NO options:options placeholderCompletionHandler:placeholderCompletionHandler resultHandler:resultHandler];
			}];

			if (isSecurityScoped && relinquishSecurityScopedResourceAccess)
			{
				[inputFileURL stopAccessingSecurityScopedResource];
			}

			if ((error != nil) && (resultHandler != nil))
			{
				// Error gaining coordinated read access => return error for import (-[OCCore importFileNamed:…] was not called)
				OCLogError(@"Error gaining coordinated read access of readURL=%@: %@", inputFileURL, error);
				resultHandler(error, self, nil, nil);
			}
		}
	}

	return (progress);
}

@end
