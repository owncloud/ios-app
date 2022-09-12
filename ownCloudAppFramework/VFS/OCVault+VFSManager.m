//
//  OCVault+VFSManager.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 19.05.22.
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

#import "OCVault+VFSManager.h"
#import "OCVFSNode+FileProviderItem.h"
#import "OCItem+FileProviderItem.h"
#import "VFSManager.h"

@implementation OCVault (VFSManager)

#pragma mark - OCVaultVFSTranslation
- (OCVFSNode *)vfsNodeForDriveID:(OCDriveID)driveID
{
	return ([self.vfs driveRootNodeForLocation:[[OCLocation alloc] initWithBookmarkUUID:self.bookmark.uuid driveID:driveID path:@"/"]]);
}

- (nullable NSSet<OCVFSItemID> *)vfsRefreshIDsForDriveChangesWithAdditions:(nullable NSArray<OCDrive *> *)addedDrives updates:(nullable NSArray<OCDrive *> *)updatedDrives removals:(nullable NSArray<OCDrive *> *)removedDrives
{
	NSMutableSet<OCVFSItemID> *vfsIDs = [NSMutableSet new];

	void(^AddDriveParents)(NSArray<OCDrive *> *drives) = ^(NSArray<OCDrive *> *drives) {
		for (OCDrive *drive in drives)
		{
			OCVFSNode *driveParentNode;

			if ((driveParentNode = [self vfsNodeForDriveID:drive.identifier].parentNode) != nil)
			{
				[vfsIDs addObject:driveParentNode.vfsItemID];
			}
		}
	};

	AddDriveParents(addedDrives);
	AddDriveParents(updatedDrives);

	if (removedDrives.count > 0)
	{
		AddDriveParents(removedDrives);

		[vfsIDs addObject:OCVFSItemIDRoot];
	}

	return (vfsIDs);
}

- (nullable NSArray<OCVFSItemID> *)vfsRefreshParentIDsForItem:(nonnull OCItem *)item
{
	// Drive-based layout with VFS
	OCVFSNode *vfsNode = nil;
	OCVFSItemID vfsItemID = nil, parentVFSItemID = nil;

	item.bookmarkUUID = self.bookmark.uuid.UUIDString;

	switch (item.type)
	{
		case OCItemTypeFile:
			if (item.path.parentPath.isRootPath)
			{
				// Parent is root
				if (item.driveID)
				{
					if ((vfsNode = [self vfsNodeForDriveID:item.driveID]) != nil)
					{
						vfsItemID = vfsNode.vfsItemID;
					}
				}
				else
				{
					vfsItemID = OCVFSItemIDRoot;
				}
			}
			else
			{
				vfsItemID = item.vfsParentItemID;
			}
		break;

		case OCItemTypeCollection:
			if (item.isRoot)
			{
				// Folder is root folder of drive
				if ((vfsNode = [self vfsNodeForDriveID:item.driveID]) != nil)
				{
					vfsItemID = vfsNode.vfsItemID;
					parentVFSItemID = vfsNode.vfsParentItemID;
				}
			}
			else
			{
				// Regular folder on drive
				vfsItemID = item.vfsItemID;

				if (item.path.parentPath.isRootPath)
				{
					// Parent folder is root folder of drive
					if ((vfsNode = [self vfsNodeForDriveID:item.driveID]) != nil)
					{
						parentVFSItemID = vfsNode.vfsItemID;
					}
				}
			}
		break;
	}

	if (vfsItemID != nil)
	{
		if (parentVFSItemID != nil)
		{
			return (@[ parentVFSItemID, vfsItemID ]);
		}

		return (@[ vfsItemID ]);
	}

	return (nil);
}

#pragma mark - OCVaultVFSProvider
- (OCVFSCore *)provideVFS
{
	return ([VFSManager.sharedManager vfsForVault:self]);
}

@end
