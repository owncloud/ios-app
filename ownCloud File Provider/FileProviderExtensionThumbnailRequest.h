//
//  FileProviderExtensionThumbnailRequest.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileProviderExtension.h"


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

@property(strong) NSProgress *progress;

- (void)requestNextThumbnail;

@end
