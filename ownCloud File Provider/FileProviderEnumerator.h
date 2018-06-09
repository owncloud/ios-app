//
//  FileProviderEnumerator.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 07.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import <FileProvider/FileProvider.h>
#import <ownCloudSDK/ownCloudSDK.h>

@interface FileProviderEnumerator : NSObject <NSFileProviderEnumerator>
{
	OCCore *_core;
	OCBookmark *_bookmark;
	NSFileProviderItemIdentifier _enumeratedItemIdentifier;

	OCQuery *_query;
}

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBookmark:(OCBookmark *)bookmark enumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier;

@property (nonatomic, readonly, strong) NSFileProviderItemIdentifier enumeratedItemIdentifier;

@end
