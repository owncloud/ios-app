//
//  OCVFSNode+FileProviderItem.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 04.05.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCVFSNode+FileProviderItem.h"
#import "OCItem+FileProviderItem.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation OCVFSNode (FileProviderItem)

- (NSString *)filename
{
	return (self.name);
}

- (NSFileProviderItemIdentifier)itemIdentifier
{
	OCVFSItemID vfsItemID = self.vfsItemID;

	if ([vfsItemID isEqual:OCVFSItemIDRoot])
	{
		return (NSFileProviderRootContainerItemIdentifier);
	}

	return (vfsItemID);
}

- (NSFileProviderItemIdentifier)parentItemIdentifier
{
	OCVFSItemID vfsParentItemID = self.vfsParentItemID;

	if ([vfsParentItemID isEqual:OCVFSItemIDRoot])
	{
		return (NSFileProviderRootContainerItemIdentifier);
	}

	return (vfsParentItemID);
}

- (UTType *)contentType
{
	return (UTTypeFolder);
}

- (NSFileProviderItemCapabilities)capabilities
{
	if (self.location != nil)
	{
		// Return capabilities of item at .location
		OCItem *locationItem;

		if ((locationItem = self.locationItem) != nil)
		{
			return (locationItem.capabilities);
		}
	}

	return (NSFileProviderItemCapabilitiesAllowsContentEnumerating);
}

@end
