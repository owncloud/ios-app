//
//  VFSManager.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 12.05.22.
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

#import "VFSManager.h"
#import "OCBookmark+AppExtensions.h"

@interface VFSManager ()
{
	NSMapTable <OCBookmarkUUID, OCVFSCore *> *_vfsCoreByBookmarkUUID;
}

@end

@implementation VFSManager

+ (VFSManager *)sharedManager
{
	static dispatch_once_t onceToken;
	static VFSManager *sharedManager;

	dispatch_once(&onceToken, ^{
		sharedManager = [[VFSManager alloc] init];
	});

	return (sharedManager);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		_vfsCoreByBookmarkUUID = [NSMapTable strongToWeakObjectsMapTable];

		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleDriveListChangeNotification:) name:OCVaultDriveListChanged object:nil];
	}

	return (self);
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self name:OCVaultDriveListChanged object:nil];
}

- (OCVFSCore *)_vfsForBookmarkUUID:(OCBookmarkUUID)bookmarkUUID setup:(void(^)(OCVFSCore *vfsCore))setupVFS
{
	OCVFSCore *vfsCore;

	@synchronized (_vfsCoreByBookmarkUUID)
	{
		if ((vfsCore = [_vfsCoreByBookmarkUUID objectForKey:bookmarkUUID]) == nil)
		{
			// Set up new VFS Core
			vfsCore = [[OCVFSCore alloc] init];
			vfsCore.delegate = self;

			// Save VFS core
			[_vfsCoreByBookmarkUUID setObject:vfsCore forKey:bookmarkUUID];

			// Setup VFS core
			setupVFS(vfsCore);
		}
	}

	return (vfsCore);
}

- (OCVFSCore *)vfsForBookmark:(OCBookmark *)bookmark
{
	return ([self _vfsForBookmarkUUID:bookmark.uuid setup:^(OCVFSCore *vfsCore) {
		// Initially populate drive list
		[self populateVFS:vfsCore forBookmark:bookmark];
	}]);
}

- (OCVFSCore *)vfsForVault:(OCVault *)vault
{
	return ([self _vfsForBookmarkUUID:vault.bookmark.uuid setup:^(OCVFSCore *vfsCore) {
		// Initially populate drive list
		[self updateVFS:vfsCore fromVault:vault];
	}]);
}

- (void)populateVFS:(OCVFSCore *)vfsCore forBookmark:(OCBookmark *)bookmark
{
	OCVault *vault;

	if ((vault = [[OCVault alloc] initWithBookmark:bookmark]) != nil)
	{
		[vault startDriveUpdates];
		[self updateVFS:vfsCore fromVault:vault];
		[vault stopDriveUpdates];
	}
}

#pragma mark - Update/create VFS nodes
- (void)updateVFS:(OCVFSCore *)vfsCore fromVault:(OCVault *)vault
{
	if ([vault.bookmark hasCapability:OCBookmarkCapabilityDrives])
	{
		if (vault.subscribedDrives.count > 0)
		{
			NSMutableArray<OCVFSNode *> *nodes = [NSMutableArray new];

			OCVFSNode *vfsRootNode = [OCVFSNode virtualFolderAtPath:@"/" location:nil];

			if (vault.bookmark.shortName.length > 0)
			{
				// Set shortname as name of the root folder (Files.app sometimes uses it as name in the navigation bar - and it would otherwise be "/")
				vfsRootNode.name = vault.bookmark.shortName;
			}

			[nodes addObject:vfsRootNode];

			for (OCDrive *drive in vault.subscribedDrives)
			{
				OCDriveSpecialType driveSpecialType = drive.specialType;

				// Only map personal space, spaces and Shares Jail (shared with me)
				if (!([driveSpecialType isEqual:OCDriveSpecialTypePersonal] ||
				      [driveSpecialType isEqual:OCDriveSpecialTypeSpace] ||
				      [driveSpecialType isEqual:OCDriveSpecialTypeShares]))
				{
					continue;
				}

				OCLocation *driveRootLocation = drive.rootLocation;
				driveRootLocation.bookmarkUUID = vault.bookmark.uuid;

				[nodes addObject:[OCVFSNode virtualFolderAtPath:[@"/" stringByAppendingPathComponent:drive.name].normalizedDirectoryPath location:driveRootLocation]];
			}

			[vfsCore setNodes:nodes];
		}
	}
	else
	{
		OCLocation *legacyRoot = [[OCLocation alloc] initWithBookmarkUUID:vault.bookmark.uuid driveID:nil path:@"/"];

		[vfsCore setNodes:@[
			[OCVFSNode virtualFolderAtPath:@"/" location:legacyRoot]
		]];
	}
}

#pragma mark -
- (void)handleDriveListChangeNotification:(NSNotification *)notification
{
	OCVault *originatingVault;

	if ((originatingVault = notification.object) != nil)
	{
		[self updateVFS:[self vfsForBookmark:originatingVault.bookmark] fromVault:originatingVault];
	}
}

#pragma mark - OCVFSCoreDelegate
- (void)acquireCoreForBookmark:(OCBookmark *)bookmark completionHandler:(void(^)(NSError * _Nullable error, OCCore * _Nullable core))completionHandler
{
	[OCCoreManager.sharedCoreManager requestCoreForBookmark:bookmark setup:nil completionHandler:^(OCCore * _Nullable core, NSError * _Nullable error) {
		completionHandler(error, core);
	}];
}

- (void)relinquishCoreForBookmark:(OCBookmark *)bookmark completionHandler:(void(^)(NSError * _Nullable error))completionHandler
{
	// Delay return by 5 to avoid immediate shutdown and reopening of cores when folder changes don't overlap
	NSTimeInterval returnDelayInterval = 5;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(returnDelayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[OCCoreManager.sharedCoreManager returnCoreForBookmark:bookmark completionHandler:^{
			completionHandler(nil);
		}];
	});
}

@end
