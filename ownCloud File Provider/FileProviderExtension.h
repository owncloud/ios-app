//
//  FileProviderExtension.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 07.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import <FileProvider/FileProvider.h>
#import <ownCloudSDK/ownCloudSDK.h>

@interface FileProviderExtension : NSFileProviderExtension
{
	OCCore *_core;
	OCBookmark *_bookmark;
}

@property(strong,nonatomic,readonly) OCCore *core;
@property(strong,nonatomic,readonly) OCBookmark *bookmark;

@end

