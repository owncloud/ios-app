//
//  OCVault+SavedSearches.m
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

#import "OCVault+SavedSearches.h"

@implementation OCVault (SavedSearches)

+ (void)load
{
	[OCKeyValueStore registerClasses:[NSSet setWithObjects:NSArray.class, OCSavedSearch.class, nil] forKey:OCKeyValueStoreKeySavedSearches];
}

- (NSArray<OCSavedSearch *> *)savedSearches
{
	NSMutableArray<OCSavedSearch *> *savedSearches = [self.keyValueStore readObjectForKey:OCKeyValueStoreKeySavedSearches];

	return (savedSearches);
}

- (void)addSavedSearch:(OCSavedSearch *)savedSearch
{
	[self willChangeValueForKey:@"savedSearches"];

	[self.keyValueStore updateObjectForKey:OCKeyValueStoreKeySavedSearches usingModifier:^id _Nullable(id  _Nullable existingObject, BOOL * _Nonnull outDidModify) {
		NSMutableArray<OCSavedSearch *> *savedSearches = OCTypedCast(existingObject, NSMutableArray);
		if (savedSearches == nil)
		{
			savedSearches = [NSMutableArray new];
		}

		[savedSearches addObject:savedSearch];

		*outDidModify = YES;
		return (savedSearches);
	}];

	[self didChangeValueForKey:@"savedSearches"];
}

- (void)updateSavedSearch:(OCSavedSearch *)savedSearch
{
	[self willChangeValueForKey:@"savedSearches"];

	[self.keyValueStore updateObjectForKey:OCKeyValueStoreKeySavedSearches usingModifier:^id _Nullable(id  _Nullable existingObject, BOOL * _Nonnull outDidModify) {
		NSMutableArray<OCSavedSearch *> *savedSearches = OCTypedCast(existingObject, NSMutableArray);
		NSUInteger countBefore;

		if (savedSearches != nil)
		{
			NSUInteger existingOffset = [savedSearches indexOfObjectPassingTest:^BOOL(OCSavedSearch * _Nonnull existingSearch, NSUInteger idx, BOOL * _Nonnull stop) {
				return ([existingSearch.uuid isEqual:savedSearch.uuid]);
			}];

			if (existingOffset != NSNotFound)
			{
				[savedSearches replaceObjectAtIndex:existingOffset withObject:savedSearch];
				*outDidModify = YES;
			}
		}

		return (savedSearches);
	}];

	[self didChangeValueForKey:@"savedSearches"];
}

- (void)deleteSavedSearch:(OCSavedSearch *)savedSearch
{
	[self willChangeValueForKey:@"savedSearches"];

	[self.keyValueStore updateObjectForKey:OCKeyValueStoreKeySavedSearches usingModifier:^id _Nullable(id  _Nullable existingObject, BOOL * _Nonnull outDidModify) {
		NSMutableArray<OCSavedSearch *> *savedSearches = OCTypedCast(existingObject, NSMutableArray);
		NSUInteger countBefore;

		if ((savedSearches != nil) && ((countBefore = savedSearches.count) > 0))
		{
			[savedSearches removeObject:savedSearch];

			if (countBefore != savedSearches.count)
			{
				*outDidModify = YES;
			}
		}

		return (savedSearches);
	}];

	[self didChangeValueForKey:@"savedSearches"];
}

- (void)addSavedSearchesObserver:(id)owner withInitial:(BOOL)initial updateHandler:(void(^)(id owner, NSArray<OCSavedSearch *> * _Nullable savedSearches, BOOL initial))updateHandler
{
	__block BOOL isInitial = initial;

	[self.keyValueStore addObserver:^(OCKeyValueStore * _Nonnull store, id  _Nullable owner, OCKeyValueStoreKey  _Nonnull key, id  _Nullable newValue) {
		NSMutableArray<OCSavedSearch *> *savedSearches = OCTypedCast(newValue, NSMutableArray);
		BOOL isInitialCall = isInitial;
		isInitial = NO;

		dispatch_async(dispatch_get_main_queue(), ^{
			updateHandler(owner, savedSearches, isInitialCall);
		});
	} forKey:OCKeyValueStoreKeySavedSearches withOwner:owner initial:initial];
}

@end

OCKeyValueStoreKey OCKeyValueStoreKeySavedSearches = @"savedSearches";
