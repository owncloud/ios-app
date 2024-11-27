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

@implementation OCCore (BundleImport)

- (nullable NSProgress *)importItemNamed:(nullable NSString *)newFileName at:(OCItem *)parentItem fromURL:(NSURL *)inputFileURL isSecurityScoped:(BOOL)isSecurityScoped options:(nullable NSDictionary<OCCoreOption,id> *)inOptions placeholderCompletionHandler:(nullable OCCorePlaceholderCompletionHandler)placeholderCompletionHandler resultHandler:(nullable OCCoreUploadResultHandler)resultHandler
{
	NSError *error = nil;
	NSMutableDictionary<OCCoreOption,id> *options = (inOptions != nil) ? [inOptions mutableCopy] : [NSMutableDictionary new];
	BOOL relinquishSecurityScopedResourceAccess = NO;
	__block NSProgress *progress = nil;

	if (isSecurityScoped)
	{
		relinquishSecurityScopedResourceAccess = [inputFileURL startAccessingSecurityScopedResource];
	}

	// Using NSFileCoordinatior with "NSFileCoordinatorReadingForUploading" transparently converts bundle-based formats like f.ex. Keynote and Pages documents to flat files
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	[fileCoordinator coordinateReadingItemAtURL:inputFileURL options:NSFileCoordinatorReadingWithoutChanges|NSFileCoordinatorReadingForUploading error:&error byAccessor:^(NSURL * _Nonnull importURL) {

		OCLogDebug(@"Coordinated read of readURL=%@, attributes=%@", importURL, [NSFileManager.defaultManager attributesOfItemAtPath:importURL.path error:nil]);

		// File pointed to by importURL may be ephermal and copies are "free" in APFS as far as space is concerned
		options[OCCoreOptionImportByCopying] = @(YES);

		progress = [self importFileNamed:newFileName at:parentItem fromURL:importURL isSecurityScoped:isSecurityScoped options:options placeholderCompletionHandler:placeholderCompletionHandler resultHandler:resultHandler];
	}];

	if (isSecurityScoped && relinquishSecurityScopedResourceAccess)
	{
		[inputFileURL stopAccessingSecurityScopedResource];
	}

	return (progress);
}

@end
