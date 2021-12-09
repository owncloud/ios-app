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
#import "ZIPArchive.h"

@implementation OCCore (BundleImport)

- (nullable NSProgress *)importItemNamed:(nullable NSString *)newFileName at:(OCItem *)parentItem fromURL:(NSURL *)inputFileURL isSecurityScoped:(BOOL)isSecurityScoped options:(nullable NSDictionary<OCCoreOption,id> *)inOptions placeholderCompletionHandler:(nullable OCCorePlaceholderCompletionHandler)placeholderCompletionHandler resultHandler:(nullable OCCoreUploadResultHandler)resultHandler
{
	OCCoreImportTransformation transformation = nil;
	NSString *resourceType=nil;
	NSError *error = nil;
	NSMutableDictionary<OCCoreOption,id> *options = (inOptions != nil) ? [inOptions mutableCopy] : [NSMutableDictionary new];
	BOOL relinquishSecurityScopedResourceAccess = NO;

	if (isSecurityScoped)
	{
		relinquishSecurityScopedResourceAccess = [inputFileURL startAccessingSecurityScopedResource];
	}

	if ([inputFileURL getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:&error])
	{
		OCLogDebug(@"Importing resourceType=%@", resourceType);
	}

	if (isSecurityScoped && relinquishSecurityScopedResourceAccess)
	{
		[inputFileURL stopAccessingSecurityScopedResource];
	}

	if (resourceType != nil)
	{
		if ([resourceType isEqual:NSURLFileResourceTypeDirectory])
		{
			NSString *bundleType = inputFileURL.pathExtension.lowercaseString;

			if ([bundleType isEqual:@"pages"] || 	// Pages
			    [bundleType isEqual:@"key"])	// Keynote
			{
				// Special handling for Pages and Keynote files
				OCLogDebug(@"Importing with transformer for bundle-document of type=%@", bundleType);

				transformation = ^(NSURL *sourceURL) {
					NSError *error = nil;
					NSURL *zipURL = [sourceURL URLByAppendingPathExtension:@".zip"];

					if ((error = [ZIPArchive compressContentsOf:sourceURL asZipFile:zipURL]) == nil)
					{
						if ([[NSFileManager defaultManager] removeItemAtURL:sourceURL error:&error])
						{
							if (![[NSFileManager defaultManager] moveItemAtURL:zipURL toURL:sourceURL error:&error])
							{
								OCLogDebug(@"Moving %@ to %@ failed with error=%@", OCLogPrivate(zipURL), OCLogPrivate(sourceURL), OCLogPrivate(error));
							}
						}
						else
						{
							OCLogDebug(@"Removing %@ failed with error=%@", OCLogPrivate(sourceURL), OCLogPrivate(error));
						}
					}
					else
					{
						OCLogDebug(@"Compressing %@ as %@ failed with error=%@", OCLogPrivate(sourceURL), OCLogPrivate(zipURL), OCLogPrivate(error));
					}

					OCLogDebug(@"Import transformation finished with error=%@", error);

					return (error);
				};

				// ZIP the document in-place after copying
				options[OCCoreOptionImportTransformation] = [transformation copy];

				// Make sure to copy the input item, as it about to be replaced
				options[OCCoreOptionImportByCopying] = @(YES);
			}
			else
			{
				// Import of directories not currently supported
				if (placeholderCompletionHandler != nil)
				{
					placeholderCompletionHandler(OCError(OCErrorFeatureNotSupportedForItem), nil);
				}

				if (resultHandler != nil)
				{
					resultHandler(OCError(OCErrorFeatureNotSupportedForItem), self, nil, nil);
				}
				return(nil);
			}
		}
	}

	return ([self importFileNamed:newFileName at:parentItem fromURL:inputFileURL isSecurityScoped:isSecurityScoped options:options placeholderCompletionHandler:placeholderCompletionHandler resultHandler:resultHandler]);
}

@end
