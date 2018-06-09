//
//  OCBookmark+FileProvider.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import "OCBookmark+FileProvider.h"

@implementation OCBookmark (FileProvider)

- (NSString *)pathRelativeToDocumentStorage
{
	return ([OCVault filesRootPathRelativeToGroupContainerForVaultUUID:self.uuid]);
}

@end
