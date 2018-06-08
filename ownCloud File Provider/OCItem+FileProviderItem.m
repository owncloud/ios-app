//
//  OCItem+FileProviderItem.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 08.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "OCItem+FileProviderItem.h"

@implementation OCItem (FileProviderItem)

@dynamic filename;

// TODO: implement an initializer to create an item from your extension's backing model
// TODO: implement the accessors to return the values from your extension's backing model

- (NSFileProviderItemIdentifier)itemIdentifier
{
	return (self.fileID);
}

- (NSFileProviderItemIdentifier)parentItemIdentifier
{
	return (self.parentFileID);
}

- (NSFileProviderItemCapabilities)capabilities
{
	switch (self.type)
	{
		case OCItemTypeFile:
			return (0);
		break;

		case OCItemTypeCollection:
			return (NSFileProviderItemCapabilitiesAllowsContentEnumerating);
		break;
	}

	return (NSFileProviderItemCapabilitiesAllowsAll);
}

- (NSString *)typeIdentifier
{
	// Convert MIME type to UTI type identifier
	return ((NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)self.mimeType, NULL)));
}

@end
