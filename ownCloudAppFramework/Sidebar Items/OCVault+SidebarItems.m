//
//  OCVault+SidebarItems.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 28.02.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCVault+SidebarItems.h"

@implementation OCVault (SidebarItems)

+ (void)load
{
	[OCKeyValueStore registerClasses:[NSSet setWithObjects:NSArray.class, OCSidebarItem.class, nil] forKey:OCKeyValueStoreKeySidebarItems];
}

- (NSArray<OCSidebarItem *> *)sidebarItems
{
	NSMutableArray<OCSidebarItem *> *sidebarItems = [self.keyValueStore readObjectForKey:OCKeyValueStoreKeySidebarItems];

	return (sidebarItems);
}

- (void)addSidebarItem:(OCSidebarItem *)sidebarItem
{
	[self willChangeValueForKey:@"sidebarItems"];

	[self.keyValueStore updateObjectForKey:OCKeyValueStoreKeySidebarItems usingModifier:^id _Nullable(id  _Nullable existingObject, BOOL * _Nonnull outDidModify) {
		NSMutableArray<OCSidebarItem *> *sidebarItems = OCTypedCast(existingObject, NSMutableArray);
		if (sidebarItems == nil)
		{
			sidebarItems = [NSMutableArray new];
		}

		[sidebarItems addObject:sidebarItem];

		*outDidModify = YES;
		return (sidebarItems);
	}];

	[self didChangeValueForKey:@"sidebarItems"];
}

- (void)updateSidebarItem:(OCSidebarItem *)sidebarItem
{
	[self willChangeValueForKey:@"sidebarItems"];

	[self.keyValueStore updateObjectForKey:OCKeyValueStoreKeySidebarItems usingModifier:^id _Nullable(id  _Nullable existingObject, BOOL * _Nonnull outDidModify) {
		NSMutableArray<OCSidebarItem *> *sidebarItems = OCTypedCast(existingObject, NSMutableArray);

		if (sidebarItems != nil)
		{
			NSUInteger existingOffset = [sidebarItems indexOfObjectPassingTest:^BOOL(OCSidebarItem * _Nonnull existingSidebarItem, NSUInteger idx, BOOL * _Nonnull stop) {
				return ([existingSidebarItem.uuid isEqual:sidebarItem.uuid]);
			}];

			if (existingOffset != NSNotFound)
			{
				[sidebarItems replaceObjectAtIndex:existingOffset withObject:sidebarItem];
				*outDidModify = YES;
			}
		}

		return (sidebarItems);
	}];

	[self didChangeValueForKey:@"sidebarItems"];
}

- (void)deleteSidebarItem:(OCSidebarItem *)sidebarItem
{
	[self willChangeValueForKey:@"sidebarItems"];

	[self.keyValueStore updateObjectForKey:OCKeyValueStoreKeySidebarItems usingModifier:^id _Nullable(id  _Nullable existingObject, BOOL * _Nonnull outDidModify) {
		NSMutableArray<OCSidebarItem *> *sidebarItems = OCTypedCast(existingObject, NSMutableArray);
		NSUInteger countBefore;

		if ((sidebarItems != nil) && ((countBefore = sidebarItems.count) > 0))
		{
			[sidebarItems removeObject:sidebarItem];

			if (countBefore != sidebarItems.count)
			{
				*outDidModify = YES;
			}
		}

		return (sidebarItems);
	}];

	[self didChangeValueForKey:@"sidebarItems"];
}

- (void)addSidebarItemObserver:(id)owner withInitial:(BOOL)initial updateHandler:(void (^)(id _Nonnull, NSArray<OCSidebarItem *> * _Nullable, BOOL))updateHandler
{
	__block BOOL isInitial = initial;

	[self.keyValueStore addObserver:^(OCKeyValueStore * _Nonnull store, id  _Nullable owner, OCKeyValueStoreKey  _Nonnull key, id  _Nullable newValue) {
		NSMutableArray<OCSidebarItem *> *sidebarItems = OCTypedCast(newValue, NSMutableArray);
		BOOL isInitialCall = isInitial;
		isInitial = NO;

		dispatch_async(dispatch_get_main_queue(), ^{
			updateHandler(owner, sidebarItems, isInitialCall);
		});
	} forKey:OCKeyValueStoreKeySidebarItems withOwner:owner initial:initial];
}

@end

OCKeyValueStoreKey OCKeyValueStoreKeySidebarItems = @"sidebarItems";
