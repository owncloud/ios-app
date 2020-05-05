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

@interface ZIPArchive : NSObject

+ (NSError *)compressContentsOf:(NSURL *)sourceDirectory asZipFile:(NSURL *)zipFileURL;
+ (nullable NSError *)compressContentsOfItems:(NSArray<DownloadItem *> *)sourceDirectorie fromBasePath:(NSString *)basePath asZipFile:(NSURL *)zipFileURL withPassword:(nullable NSString *)password;

@end

extern NSErrorDomain LibZipErrorDomain;

NS_ASSUME_NONNULL_END
