//
//  OCSidebarItem.h
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

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

typedef NSString* OCSidebarItemUUID;

NS_ASSUME_NONNULL_BEGIN

@interface OCSidebarItem : NSObject <NSSecureCoding, OCDataItem, OCDataItemVersioning>

@property(strong,readonly) OCSidebarItemUUID uuid;
@property(strong,nullable) OCLocation *location;

- (instancetype)initWithLocation:(OCLocation *)location;

@end

extern OCDataItemType OCDataItemTypeSidebarItem;

NS_ASSUME_NONNULL_END
