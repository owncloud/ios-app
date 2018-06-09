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
	if ([[self.path stringByDeletingLastPathComponent] isEqualToString:@"/"])
	{
		return (NSFileProviderRootContainerItemIdentifier);
	}

	return (self.parentFileID);
}

- (NSString *)filename
{
	return (self.name);
}

- (NSString *)typeIdentifier
{
	// Return special UTI type for folders
	if (self.type == OCItemTypeCollection)
	{
		return ((__bridge NSString *)kUTTypeFolder);
	}

	// Convert MIME type to UTI type identifier
	return ((NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)self.mimeType, NULL)));
}

- (NSFileProviderItemCapabilities)capabilities
{
	switch (self.type)
	{
		case OCItemTypeFile:
			return (NSFileProviderItemCapabilitiesAllowsAll);
		break;

		case OCItemTypeCollection:
			return (NSFileProviderItemCapabilitiesAllowsContentEnumerating);
		break;
	}

	return (NSFileProviderItemCapabilitiesAllowsAll);
}

- (NSData *)versionIdentifier
{
	return ([[NSString stringWithFormat:@"%@_:_%@", self.eTag, self.fileID] dataUsingEncoding:NSUTF8StringEncoding]);
}

@end
