//
//  OCItem+FileProviderItem.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 08.06.18.
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
//			return (NSFileProviderItemCapabilitiesAllowsReparenting |
//				NSFileProviderItemCapabilitiesAllowsRenaming |
//				NSFileProviderItemCapabilitiesAllowsTrashing |
//				NSFileProviderItemCapabilitiesAllowsDeleting);
		break;

		case OCItemTypeCollection:
			return (NSFileProviderItemCapabilitiesAllowsContentEnumerating |
				NSFileProviderItemCapabilitiesAllowsReparenting |
				NSFileProviderItemCapabilitiesAllowsRenaming |
				NSFileProviderItemCapabilitiesAllowsDeleting |
				NSFileProviderItemCapabilitiesAllowsAddingSubItems);
		break;
	}

	return (NSFileProviderItemCapabilitiesAllowsAll);
}

- (NSData *)versionIdentifier
{
	return ([[NSString stringWithFormat:@"%@_:_%@", self.eTag, self.fileID] dataUsingEncoding:NSUTF8StringEncoding]);
}

- (NSNumber *)documentSize
{
	if (self.type == OCItemTypeFile)
	{
		return (@(self.size));
	}

	return (nil);
}

- (BOOL)isDownloading
{
	return ((self.syncActivity & OCItemSyncActivityDownloading) == OCItemSyncActivityDownloading);
}

- (BOOL)isDownloaded
{
	if (self.localRelativePath != nil)
	{
		return (YES);
	}

	return (NO);
}

- (BOOL)isUploading
{
	return ((self.syncActivity & OCItemSyncActivityUploading) == OCItemSyncActivityUploading);
}

- (BOOL)isUploaded
{
	if (![self isUploading])
	{
		return (!self.locallyModified);
	}

	return (NO);
}

- (BOOL)isMostRecentVersionDownloaded
{
	if ((self.localRelativePath != nil) && (self.remoteItem == nil))
	{
		return (YES);
	}

	return (NO);
}

//- (BOOL)respondsToSelector:(SEL)aSelector
//{
//	NSLog(@"Probing for %@", NSStringFromSelector(aSelector));
//
//	return ([super respondsToSelector:aSelector]);
//}
//

- (NSDate *)contentModificationDate
{
	return (self.lastModified);
}

- (NSNumber *)childItemCount
{
	if (self.type == OCItemTypeFile)
	{
		return (@(0));
	}

	return (nil);
}

@end
