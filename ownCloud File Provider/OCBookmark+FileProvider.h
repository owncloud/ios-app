//
//  OCBookmark+FileProvider.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import <ownCloudSDK/ownCloudSDK.h>

@interface OCBookmark (FileProvider)

- (NSString *)pathRelativeToDocumentStorage; //!< "The path of the domain's subdirectory relative to the file provider's shared container."

@end
