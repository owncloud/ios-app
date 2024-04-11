//
//  OCVault+SavedSearches.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 13.09.22.
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "OCSavedSearch.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCVault (SavedSearches)

@property(readonly,strong,nullable) NSArray<OCSavedSearch *> *savedSearches;

- (void)addSavedSearch:(OCSavedSearch *)savedSearch;
- (void)updateSavedSearch:(OCSavedSearch *)savedSearch;
- (void)deleteSavedSearch:(OCSavedSearch *)savedSearch;

- (void)addSavedSearchesObserver:(id)owner withInitial:(BOOL)initial updateHandler:(void(^)(id owner, NSArray<OCSavedSearch *> * _Nullable savedSearches, BOOL initial))updateHandler;

@end

extern OCKeyValueStoreKey OCKeyValueStoreKeySavedSearches;

NS_ASSUME_NONNULL_END
