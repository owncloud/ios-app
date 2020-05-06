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
#import "OCCore+BundleImport.h"


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

@implementation ZipFileItem

- (instancetype)initWithFilepath:(NSString *)filepath isDirectory:(BOOL)isDirectory absolutePath:(NSString *)absolutePath
{
	if ((self = [super init]) != nil)
	{
		self.filepath = filepath;
		self.isDirectory = isDirectory;
		self.absolutePath = absolutePath;
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

+ (nullable NSError *)compressContentsOfItems:(NSArray<DownloadItem *> *)sourceItems fromBasePath:(NSString *)basePath asZipFile:(NSURL *)zipFileURL withPassword:(nullable NSString *)password
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

+ (NSArray<ZipFileItem *> *)uncompressContentsOfZipFile:(NSURL *)zipFileURL parentItem:(OCItem *)parentItem withPassword:(nullable NSString *)password withCore:(OCCore *)core
{
	NSMutableArray *zipItems = [NSMutableArray new];
	zip_t *zipArchive = NULL;
	int zipError = ZIP_ER_OK;
    struct zip_stat sb;
    struct zip_file *zf;

    char buf[100];
    long long sum;
    NSInteger len;
	NSError *error = nil;

	NSError *(^ErrorFromZipArchive)(zip_t *zipArchive) = ^(zip_t *zipArchive) {
		zip_error_t *zipError = zip_get_error(zipArchive);

		return ([NSError errorWithDomain:LibZipErrorDomain code:zipError->zip_err userInfo:nil]);
	};

	if ((zipArchive = zip_open(zipFileURL.path.UTF8String, ZIP_RDONLY, &zipError)) != NULL)
	{
		NSURL *tmpURL = [zipFileURL URLByDeletingPathExtension];

		[NSFileManager.defaultManager createDirectoryAtURL:tmpURL withIntermediateDirectories:NO attributes:nil error:nil];

		   for (NSInteger i = 0; i < zip_get_num_entries(zipArchive, 0); i++) {
			   if (zip_stat_index(zipArchive, i, 0, &sb) == 0) {
				   printf("==================/n");
				   len = strlen(sb.name);
				   printf("Name: [%s], ", sb.name);
				   printf("Size: [%llu], ", sb.size);
				   printf("mtime: [%u]/n", (unsigned int)sb.mtime);


				   NSString *filePath = [tmpURL.path stringByAppendingPathComponent:[NSString stringWithUTF8String:sb.name]];
				   
				   if (sb.name[len - 1] == '/') {
					   //safe_create_dir(sb.name);
					   ZipFileItem *item = [[ZipFileItem alloc] initWithFilepath:[NSString stringWithUTF8String:sb.name] isDirectory:YES absolutePath:filePath];
					   [zipItems addObject:item];
					   NSLog(@"--> create dir: %s", sb.name);
					   [NSFileManager.defaultManager createDirectoryAtURL:[tmpURL URLByAppendingPathComponent:[NSString stringWithUTF8String:sb.name]] withIntermediateDirectories:NO attributes:nil error:nil];
				   } else {
					   NSLog(@"--> read file: %s", sb.name);
					   zf = zip_fopen_index(zipArchive, i, 0);
					   if (!zf) {
						   error = ErrorFromZipArchive(zipArchive);
						   OCLogError(@"Error opening zip file %@", error);
					   }

					   NSMutableData *data = [NSMutableData new];
					   sum = 0;
					   while (sum != sb.size) {
						   len = zip_fread(zf, buf, 100);
						   if (len < 0) {
							   error = ErrorFromZipArchive(zipArchive);
							   OCLogError(@"Error reading zip file %@", error);
						   }
						   [data appendBytes:buf length:len];
						   sum += len;
					   }

					   [NSFileManager.defaultManager createFileAtPath:filePath contents:data attributes:nil];

					   ZipFileItem *item = [[ZipFileItem alloc] initWithFilepath:[NSString stringWithUTF8String:sb.name] isDirectory:NO absolutePath:filePath];
					   [zipItems addObject:item];

					   NSLog(@"--> zipitems %@", zipItems);

					   zip_fclose(zf);
				   }
			   } else {
				   printf("File[%s] Line[%d]/n", __FILE__, __LINE__);
			   }
		   }

	}

	if (zip_close(zipArchive) < 0)
	{
		// Error
		error = ErrorFromZipArchive(zipArchive);
		OCLogError(@"Error closing zip archive %@: %@", zipFileURL.path, error);

		zip_discard(zipArchive);
	}

	return zipItems;
	//return (error);
}

@end

NSErrorDomain LibZipErrorDomain = @"LibZIPErrorDomain";
