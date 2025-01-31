//
//  NSURL+OCVaultTools.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 30.01.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (OCVaultTools)

@property(readonly,nonatomic) BOOL isLocatedWithinVaultStorage; //!< URL points to a location within OCVault.storageRootURL
@property(readonly,nonatomic) BOOL isLocalFile; //!< URL points to a file:// that exists and is actually a file (=> not a folder, ..)

@end

NS_ASSUME_NONNULL_END
