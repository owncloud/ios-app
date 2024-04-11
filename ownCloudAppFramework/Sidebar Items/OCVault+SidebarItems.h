//
//  OCVault+SidebarItems.h
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "OCSidebarItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCVault (SidebarItems)

@property(readonly,strong,nullable) NSArray<OCSidebarItem *> *sidebarItems;

- (void)addSidebarItem:(OCSidebarItem *)sidebarItem;
- (void)updateSidebarItem:(OCSidebarItem *)sidebarItem;
- (void)deleteSidebarItem:(OCSidebarItem *)sidebarItem;

- (void)addSidebarItemObserver:(id)owner withInitial:(BOOL)initial updateHandler:(void(^)(id owner, NSArray<OCSidebarItem *> * _Nullable sidebarItems, BOOL initial))updateHandler;

@end

extern OCKeyValueStoreKey OCKeyValueStoreKeySidebarItems;

NS_ASSUME_NONNULL_END
