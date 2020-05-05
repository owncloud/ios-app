//
//  ZIPArchive.m
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

#import <ownCloudSDK/ownCloudSDK.h>
#import <libzip/libzip.h>
#import "ZIPArchive.h"


@implementation DownloadItem

- (instancetype)initWithFile:(OCFile *)file item:(OCItem *)item
{
	if ((self = [super init]) != nil)
	{
		self.file = file;
		self.item = item;
	}

	return(self);
}

@end

@implementation ZIPArchive

+ (NSError *)compressContentsOf:(NSURL *)sourceDirectory asZipFile:(NSURL *)zipFileURL
{
	zip_t *zipArchive = NULL;
	int zipError = ZIP_ER_OK;
	NSError *error = nil;
	NSError *(^ErrorFromZipArchive)(zip_t *zipArchive) = ^(zip_t *zipArchive) {
		zip_error_t *zipError = zip_get_error(zipArchive);

		return ([NSError errorWithDomain:LibZipErrorDomain code:zipError->zip_err userInfo:nil]);
	};

	if ((zipArchive = zip_open(zipFileURL.path.UTF8String, ZIP_CREATE, &zipError)) != NULL)
	{
		NSDirectoryEnumerator<NSURL *> *directoryEnumerator;

		NSUInteger basePathLength = sourceDirectory.path.length;

		if (![sourceDirectory.path hasSuffix:@"/"])
		{
			basePathLength++;
		}

		if ((directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:sourceDirectory includingPropertiesForKeys:@[NSURLFileSizeKey,NSURLIsDirectoryKey] options:0 errorHandler:nil]) != nil)
		{
			for (NSURL *addURL in directoryEnumerator)
			{
				zip_source_t *fileSource = NULL;
				NSNumber *isDirectory = nil, *size = nil;
				NSString *relativePath = [addURL.path substringFromIndex:basePathLength];

				if (relativePath.length == 0)
				{
					continue;
				}

				[addURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
				[addURL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];

				if (isDirectory.boolValue)
				{
					// Add directory
					OCLogDebug(@"Adding directory %@ from %@", relativePath, addURL);

					if (zip_dir_add(zipArchive, relativePath.UTF8String, ZIP_FL_ENC_UTF_8) < 0)
					{
						// Error
						error = ErrorFromZipArchive(zipArchive);
						OCLogError(@"Error adding directory %@: %@", relativePath, error);
					}
				}
				else
				{
					// Add file
					OCLogDebug(@"Adding file %@ from %@", relativePath, addURL);

					if ((fileSource = zip_source_file(zipArchive, addURL.path.UTF8String, 0, (zip_int64_t)size.unsignedIntegerValue)) != NULL)
					{
						if (zip_file_add(zipArchive, relativePath.UTF8String, fileSource, ZIP_FL_ENC_UTF_8) < 0)
						{
							// Error
							error = ErrorFromZipArchive(zipArchive);
							OCLogError(@"Error compressing %@: %@", relativePath, error);

							zip_source_free(fileSource);
						}
					}
					else
					{
						// Error
						error = ErrorFromZipArchive(zipArchive);
						OCLogError(@"Error adding directory %@: %@", relativePath, error);
					}
				}
			}
		} else {
			NSURL *addURL =  sourceDirectory;
			zip_source_t *fileSource = NULL;
			NSNumber *isDirectory = nil, *size = nil;

			NSString *relativePath = addURL.path.lastPathComponent;
			[addURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
			[addURL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];

				// Add file
				if ((fileSource = zip_source_file(zipArchive, addURL.path.UTF8String, 0, (zip_int64_t)size.unsignedIntegerValue)) != NULL)
				{
					if (zip_file_add(zipArchive, relativePath.UTF8String, fileSource, ZIP_FL_ENC_UTF_8) < 0)
					{
						// Error
						error = ErrorFromZipArchive(zipArchive);
						OCLogError(@"Error compressing %@: %@", relativePath, error);

						zip_source_free(fileSource);
					}
				}
				else
				{
					// Error
					error = ErrorFromZipArchive(zipArchive);
					OCLogError(@"Error adding directory %@: %@", relativePath, error);
				}
		}

		if (zip_close(zipArchive) < 0)
		{
			// Error
			error = ErrorFromZipArchive(zipArchive);
			OCLogError(@"Error closing zip archive %@: %@", zipFileURL.path, error);

			zip_discard(zipArchive);
		}
	}
	else
	{
		// Error
		error = [NSError errorWithDomain:LibZipErrorDomain code:zipError userInfo:nil];
		OCLogError(@"Error opening zip archive %@: %@", zipFileURL.path, error);
	}

	return (error);
}

+ (NSError *)compressContentsOfItems:(NSArray<DownloadItem *> *)sourceItems fromBasePath:(NSString *)basePath asZipFile:(NSURL *)zipFileURL withPassword:(nullable NSString *)password
{
	zip_t *zipArchive = NULL;
	int zipError = ZIP_ER_OK;
	NSError *error = nil;
	NSError *(^ErrorFromZipArchive)(zip_t *zipArchive) = ^(zip_t *zipArchive) {
		zip_error_t *zipError = zip_get_error(zipArchive);

		return ([NSError errorWithDomain:LibZipErrorDomain code:zipError->zip_err userInfo:nil]);
	};

	if ((zipArchive = zip_open(zipFileURL.path.UTF8String, ZIP_CREATE, &zipError)) != NULL)
	{
		zip_uint64_t index = 0;
		for (DownloadItem *sourceItem in sourceItems)
		{
			NSURL *addURL = sourceItem.file.url;
			zip_source_t *fileSource = NULL;
			NSNumber *size = nil;
			NSString *relativePath = [sourceItem.item.path stringByReplacingOccurrencesOfString:basePath withString:@"/"];

			if (sourceItem.item.type == OCItemTypeCollection)
			{
				// Add directory
				OCLogDebug(@"Adding directory %@ from %@", relativePath, addURL);

				if (zip_dir_add(zipArchive, relativePath.UTF8String, ZIP_FL_ENC_UTF_8) < 0)
				{
					// Error
					error = ErrorFromZipArchive(zipArchive);
					OCLogError(@"Error adding directory %@: %@", relativePath, error);
				}
			}
			else
			{
				// Add file
				OCLogDebug(@"Adding file %@ from %@", relativePath, addURL);

				if ((fileSource = zip_source_file(zipArchive, addURL.path.UTF8String, 0, (zip_int64_t)size.unsignedIntegerValue)) != NULL)
				{
					if (zip_file_add(zipArchive, relativePath.UTF8String, fileSource, ZIP_FL_ENC_UTF_8) < 0)
					{
						// Error
						error = ErrorFromZipArchive(zipArchive);
						OCLogError(@"Error compressing %@: %@", relativePath, error);

						zip_source_free(fileSource);
					} else {
						if (password != nil) {
							zip_file_set_encryption(zipArchive, index, ZIP_EM_AES_256, (const char*)[password UTF8String]);
						}
						index ++;
					}
				}
				else
				{
					// Error
					error = ErrorFromZipArchive(zipArchive);
					OCLogError(@"Error adding directory %@: %@", relativePath, error);
				}
			}
		}
	}
	else
	{
		// Error
		error = [NSError errorWithDomain:LibZipErrorDomain code:zipError userInfo:nil];
		OCLogError(@"Error opening zip archive %@: %@", zipFileURL.path, error);
	}

	if (zip_close(zipArchive) < 0)
	{
		// Error
		error = ErrorFromZipArchive(zipArchive);
		OCLogError(@"Error closing zip archive %@: %@", zipFileURL.path, error);

		zip_discard(zipArchive);
	}

	return (error);
}

@end

NSErrorDomain LibZipErrorDomain = @"LibZIPErrorDomain";
