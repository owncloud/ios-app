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

#import <CoreServices/CoreServices.h>

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

+ (NSDictionary<NSString*, NSString*> *)overriddenUTIByMIMEType
{
	static dispatch_once_t onceToken;
	static NSDictionary<NSString *, NSString *> *utiByMIMEType;

	dispatch_once(&onceToken, ^{
		utiByMIMEType = @{
			@"application/vnd.oasis.opendocument.text" 			: @"org.oasis-open.opendocument.text",
			@"application/vnd.oasis.opendocument.text-template" 		: @"org.oasis-open.opendocument.text-template",

			@"application/vnd.oasis.opendocument.graphics" 			: @"org.oasis-open.opendocument.graphics",
			@"application/vnd.oasis.opendocument.graphics-template" 	: @"org.oasis-open.opendocument.graphics-template",

			@"application/vnd.oasis.opendocument.presentation" 		: @"org.oasis-open.opendocument.presentation",
			@"application/vnd.oasis.opendocument.presentation-template" 	: @"org.oasis-open.opendocument.presentation-template",

			@"application/vnd.oasis.opendocument.spreadsheet" 		: @"org.oasis-open.opendocument.spreadsheet",
			@"application/vnd.oasis.opendocument.spreadsheet-template" 	: @"org.oasis-open.opendocument.spreadsheet-template",

			@"application/vnd.oasis.opendocument.formula" 			: @"org.oasis-open.opendocument.formula",
			@"application/vnd.oasis.opendocument.formula-template" 		: @"org.oasis-open.opendocument.formula-template",

			/*
				These MIME-Types aren't correctly mapped by iOS, so they're hardcoded. Reference:
				- OC10 suffix -> MIMEType map: https://github.com/owncloud/core/blob/master/resources/config/mimetypemapping.dist.json
				- Apple UTI reference table: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
			*/
			@"application/illustrator"					: @"com.adobe.illustrator.ai-image",

			@"application/x-perl"						: @"public.perl-script",
			@"application/x-php"						: @"public.php-script",
			@"text/x-python"						: @"public.python-script",
			@"text/x-c"							: @"public.c-source",
			@"text/x-c++src"						: @"public.c-plus-plus-source",
			@"text/x-h"							: @"public.c-header",
			@"text/markdown"						: @"net.daringfireball.markdown",
			@"text/x-shellscript"						: @"public.shell-script",
			@"text/x-java-source"						: @"com.sun.java-source"

//			@"audio/ogg"							: @"org.xiph.oga",
//			@"video/ogg"							: @"org.xiph.ogv"
		};
	});

	return (utiByMIMEType);
}

+ (NSDictionary<NSString*, NSString*> *)overriddenUTIBySuffix
{
	static dispatch_once_t onceToken;
	static NSDictionary<NSString *, NSString *> *utiBySuffix;

	dispatch_once(&onceToken, ^{
		utiBySuffix = @{
			// These suffix -> UTI mappings are currently not needed as the OC server
			// already returns correct MIME-Types for these, so the MIMEType -> UTI
			// mapping already takes care of it. Decided to let them still stay here
			// as a reference and to document the thinking behind not including these
			// five file types in this conversion dictionary.

			// @"odt" : @"org.oasis-open.opendocument.text",
			// @"ott" : @"org.oasis-open.opendocument.text-template",

			// @"odg" : @"org.oasis-open.opendocument.graphics",
			// @"otg" : @"org.oasis-open.opendocument.graphics-template",

			// @"odp" : @"org.oasis-open.opendocument.presentation",
			// @"otp" : @"org.oasis-open.opendocument.presentation-template",

			// @"ods" : @"org.oasis-open.opendocument.spreadsheet",
			// @"ots" : @"org.oasis-open.opendocument.spreadsheet-template",

			// @"odf" : @"org.oasis-open.opendocument.formula",
			// @"otf" : @"org.oasis-open.opendocument.formula-template",


			// OC server does not seem to return MIME Types for these types
			// at the time of writing, so these entries take care of correctly
			// mapping suffixes to UTIs

			@"odc" 		: @"org.oasis-open.opendocument.chart",
			@"otc" 		: @"org.oasis-open.opendocument.chart-template",

			@"odi" 		: @"org.oasis-open.opendocument.image",
			@"oti" 		: @"org.oasis-open.opendocument.image-template",

			@"odm" 		: @"org.oasis-open.opendocument.text-master",
			@"oth" 		: @"org.oasis-open.opendocument.text-web",

			@"m"		: @"public.objective-c-source",

			@"mindnode"	: @"com.mindnode.mindnode.mindmap",
			@"itmz"		: @"com.toketaware.uti.ithoughts.itmz",
			
			@"pdf"		: @"com.adobe.pdf"
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
	if (uti == nil)
	{
		// Override by MIMEType
		if (self.mimeType != nil)
		{
			uti = OCItem.overriddenUTIByMIMEType[self.mimeType];

			OCLogVerbose(@"Mapped %@ MIMEType %@ to UTI %@", self.name, self.mimeType, uti);
		}
	}

	if (uti == nil)
	{
		NSString *suffix;

		// Override by suffix
		if ((suffix = self.name.pathExtension.lowercaseString) != nil)
		{
			uti = OCItem.overriddenUTIBySuffix[suffix];

			OCLogVerbose(@"Mapped %@ suffix %@ to UTI %@", self.name, suffix, uti);
		}
	}

	// Convert MIME type to UTI type identifier
	if (uti == nil)
	{
		if (self.mimeType != nil)
		{
			uti = ((NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)self.mimeType, NULL)));
		}
		else
		{
			uti = (__bridge NSString *)kUTTypeData;
		}

		OCLogVerbose(@"Converted %@ MIMEType %@ to UTI %@", self.name, self.mimeType, uti);
	}

	// Reject "dyn.*" types
	if ([uti hasPrefix:@"dyn."])
	{
		// Use generic data UTI instead
		// Rationale: https://github.com/owncloud/ios-app/issues/747#issuecomment-689797261
		uti = (__bridge NSString *)kUTTypeData;
		OCLogVerbose(@"Rejected dynamic %@ UTI for %@, using %@ instead", self.name, self.mimeType, uti);
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

	if (self.type == OCItemTypeCollection)
	{
		// Needs to return YES for folders in order to allow browsing while offline
		// Otherwise Files.app will bring up an alert "You're not connected to the Internet"
		// (big thanks to @palmin who pointed me to this possibility)
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
