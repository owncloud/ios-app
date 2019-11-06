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
#import "NSError+MessageResolution.h"

static NSMutableDictionary<OCLocalID, NSError *> *sOCItemUploadingErrors;

@implementation OCItem (FileProviderItem)

@dynamic filename;

// TODO: implement an initializer to create an item from your extension's backing model
// TODO: implement the accessors to return the values from your extension's backing model

- (NSFileProviderItemIdentifier)itemIdentifier
{
	if ([self.path isEqual:@"/"])
	{
		return (NSFileProviderRootContainerItemIdentifier);
	}

	return (self.localID);
}

- (NSFileProviderItemIdentifier)parentItemIdentifier
{
	if ([[self.path stringByDeletingLastPathComponent] isEqualToString:@"/"])
	{
		return (NSFileProviderRootContainerItemIdentifier);
	}

	return (self.parentLocalID);
}

- (NSString *)filename
{
	return (self.name);
}

+ (NSDictionary<NSString*, NSString*> *)overriddenUTIBySuffix
{
	static dispatch_once_t onceToken;
	static NSDictionary<NSString *, NSString *> *utiBySuffix;

	dispatch_once(&onceToken, ^{
		utiBySuffix = @{
			@"odt" : @"org.oasis-open.opendocument.text",
			@"ott" : @"org.oasis-open.opendocument.text-template",

			@"odg" : @"org.oasis-open.opendocument.graphics",
			@"otg" : @"org.oasis-open.opendocument.graphics-template",

			@"odp" : @"org.oasis-open.opendocument.presentation",
			@"otp" : @"org.oasis-open.opendocument.presentation-template",

			@"ods" : @"org.oasis-open.opendocument.spreadsheet",
			@"ots" : @"org.oasis-open.opendocument.spreadsheet-template",

			@"odc" : @"org.oasis-open.opendocument.chart",
			@"otc" : @"org.oasis-open.opendocument.chart-template",

			@"odi" : @"org.oasis-open.opendocument.image",
			@"oti" : @"org.oasis-open.opendocument.image-template",

			@"odf" : @"org.oasis-open.opendocument.formula",
			@"otf" : @"org.oasis-open.opendocument.formula-template",

			@"odm" : @"org.oasis-open.opendocument.text-master",
			@"oth" : @"org.oasis-open.opendocument.text-web",
		};
	});

	return (utiBySuffix);
}

- (NSString *)typeIdentifier
{
	NSString *uti = nil;

	// Return special UTI type for folders
	if (self.type == OCItemTypeCollection)
	{
		return ((__bridge NSString *)kUTTypeFolder);
	}

	// Workaround for broken MIMEType->UTI conversions
	NSString *suffix;

	if ((suffix = self.name.pathExtension.lowercaseString) != nil)
	{
		uti = OCItem.overriddenUTIBySuffix[suffix];

		OCLogDebug(@"Mapped %@ MIMEType %@ to UTI %@", self.name, self.mimeType, uti);
	}

	// Convert MIME type to UTI type identifier
	if (uti == nil)
	{
		uti = ((NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)self.mimeType, NULL)));

		OCLogDebug(@"Converted %@ MIMEType %@ to UTI %@", self.name, self.mimeType, uti);
	}

	return (uti);
}

- (NSFileProviderItemCapabilities)capabilities
{
	OCItemPermissions permissions = self.permissions;

	switch (self.type)
	{
		case OCItemTypeFile:
			return (
				NSFileProviderItemCapabilitiesAllowsReading |
				((permissions & OCItemPermissionWritable) 	? NSFileProviderItemCapabilitiesAllowsWriting     : 0) |
				((permissions & OCItemPermissionMove)     	? NSFileProviderItemCapabilitiesAllowsReparenting : 0) |
				((permissions & OCItemPermissionRename)   	? NSFileProviderItemCapabilitiesAllowsRenaming    : 0) |
				((permissions & OCItemPermissionDelete) 	? NSFileProviderItemCapabilitiesAllowsDeleting    : 0)
			);
		break;

		case OCItemTypeCollection:
			return (NSFileProviderItemCapabilitiesAllowsContentEnumerating |
				((permissions & OCItemPermissionMove)     					? NSFileProviderItemCapabilitiesAllowsReparenting 	: 0) |
				((permissions & OCItemPermissionRename)   					? NSFileProviderItemCapabilitiesAllowsRenaming    	: 0) |
				((permissions & OCItemPermissionDelete) 				   	? NSFileProviderItemCapabilitiesAllowsDeleting    	: 0) |
				((permissions & (OCItemPermissionCreateFile|OCItemPermissionCreateFolder)) 	? NSFileProviderItemCapabilitiesAllowsAddingSubItems 	: 0)
			);
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
	if (((self.localRelativePath != nil) && (self.remoteItem == nil)) || self.isUploading)
	{
		return (YES);
	}

	return (NO);
}

//- (BOOL)respondsToSelector:(SEL)aSelector
//{
//	OCLogDebug(@"Probing for %@", NSStringFromSelector(aSelector));
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

- (void)setLocalFavoriteRank:(NSNumber *)localFavoriteRank
{
	[self setValue:localFavoriteRank forLocalAttribute:OCLocalAttributeFavoriteRank];
}

- (NSNumber *)favoriteRank
{
	NSNumber *favoriteRank = [self valueForLocalAttribute:OCLocalAttributeFavoriteRank];

//	NSNumber *favoriteRank = nil;
//
//	if (self.isFavorite)
//	{
//		if ((favoriteRank = [self valueForLocalAttribute:OCLocalAttributeFavoriteRank]) == nil)
//		{
//			favoriteRank = @(NSFileProviderFavoriteRankUnranked);
//		}
//	}

	return (favoriteRank);
}

- (void)setLocalTagData:(NSData *)localTagData
{
	[self setValue:localTagData forLocalAttribute:OCLocalAttributeTagData];
}

- (NSData *)tagData
{
	return ([self valueForLocalAttribute:OCLocalAttributeTagData]);
}

- (NSError *)uploadingError
{
	if (self.localID != nil)
	{
		if (self.isPlaceholder)
		{
			NSLog(@"Request uploadingError for %@", self.localID);
		}

		@synchronized ([OCItem class])
		{
			return (sOCItemUploadingErrors[self.localID]);
		}
	}

	return (nil);
}

- (void)setUploadingError:(NSError *)uploadingError
{
	NSLog(@"Set uploadingError for %@ to %@", self.localID, uploadingError);

	if (self.localID != nil)
	{
		@synchronized ([OCItem class])
		{
			if (sOCItemUploadingErrors == nil)
			{
				sOCItemUploadingErrors = [NSMutableDictionary new];
			}

			sOCItemUploadingErrors[self.localID] = [uploadingError translatedError];
		}
	}
}

@end
