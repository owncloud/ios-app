//
//  FileProviderExtensionThumbnailRequest.h
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

#import <Foundation/Foundation.h>
#import "FileProviderExtension.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FileProviderExtensionThumbnailRequestPerThumbnailCompletionHandler)(NSFileProviderItemIdentifier identifier, NSData * _Nullable imageData, NSError * _Nullable error);
typedef void (^FileProviderExtensionThumbnailRequestCompletionHandler)(NSError * _Nullable error);

@interface FileProviderExtensionThumbnailRequest : NSObject
{
	BOOL _isDone;
}

@property(strong) FileProviderExtension *extension;

@property(strong) NSArray<NSFileProviderItemIdentifier> *itemIdentifiers;
@property(assign) NSUInteger cursorPosition;

@property(assign) CGSize sizeInPixels;

@property(copy) FileProviderExtensionThumbnailRequestPerThumbnailCompletionHandler perThumbnailCompletionHandler;
@property(copy) FileProviderExtensionThumbnailRequestCompletionHandler completionHandler;

@property(nullable,strong) NSProgress *progress;

- (void)requestNextThumbnail;

@end

NS_ASSUME_NONNULL_END
