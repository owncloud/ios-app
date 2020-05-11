//
//  ZIPArchive.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloadItem : NSObject
{
	OCFile *_file;
	OCItem *_item;
}

@property(strong,nonatomic) OCFile *file;
@property(strong,nonatomic) OCItem *item;

- (instancetype)initWithFile:(OCFile *)file item:(OCItem *)item;

@end

@interface ZipFileItem : NSObject
{
	NSString *_filepath;
	BOOL _isDirectory;
	NSString *_absolutePath;
}

@property(strong,nonatomic) NSString *filepath;
@property(assign,nonatomic) BOOL isDirectory;
@property(strong,nonatomic) NSString *absolutePath;

- (instancetype)initWithFilepath:(NSString *)filepath isDirectory:(BOOL)isDirectory absolutePath:(NSString *)absolutePath;

@end

@interface ZIPArchive : NSObject

+ (NSError *)compressContentsOf:(NSURL *)sourceDirectory asZipFile:(NSURL *)zipFileURL;
+ (nullable NSError *)compressContentsOfItems:(NSArray<DownloadItem *> *)sourceDirectorie fromBasePath:(NSString *)basePath asZipFile:(NSURL *)zipFileURL withPassword:(nullable NSString *)password;
+ (NSArray<ZipFileItem *> *)uncompressContentsOfZipFile:(NSURL *)zipFileURL parentItem:(OCItem *)parentItem withPassword:(nullable NSString *)password withCore:(OCCore *)core;
+ (BOOL)isZipFileEncrypted:(NSURL *)zipFileURL;
+ (BOOL)checkPassword:(NSString *)password forZipFile:(NSURL *)zipFileURL;

@end

extern NSErrorDomain LibZipErrorDomain;

NS_ASSUME_NONNULL_END
