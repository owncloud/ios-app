//
//  OCBookmark+AppExtensions.h
//  ownCloud
//
//  Created by Felix Schwarz on 08.07.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCBookmark (AppExtensions)

@property(readonly,strong,nonatomic,nullable) NSString *userName;
@property(strong,nonatomic,nullable) NSString *displayName;
@property(readonly,strong,nonatomic) NSString *shortName;

@end

extern OCBookmarkUserInfoKey OCBookmarkUserInfoKeyDisplayName;

NS_ASSUME_NONNULL_END
