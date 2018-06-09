//
//  OCCore+FileProviderTools.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import "OCCore+FileProviderTools.h"

@implementation OCCore (FileProviderTools)

- (OCItem *)synchronousRetrieveItemFromDatabaseForFileID:(OCFileID)fileID syncAnchor:(OCSyncAnchor __autoreleasing *)outSyncAnchor error:(NSError * __autoreleasing *)outError
{
	__block OCItem *item = nil;

	dispatch_group_t waitForRetrievalGroup = dispatch_group_create();

	dispatch_group_enter(waitForRetrievalGroup);

	[self.vault.database retrieveCacheItemForFileID:fileID completionHandler:^(OCDatabase *db, NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
		item = itemFromDatabase;

		if (outSyncAnchor != NULL)
		{
			*outSyncAnchor = syncAnchor;
		}

		if (outError != NULL)
		{
			*outError = error;
		}

		dispatch_group_leave(waitForRetrievalGroup);
	}];

	dispatch_group_wait(waitForRetrievalGroup, DISPATCH_TIME_FOREVER);

	/*
	dispatch_group_t waitForDatabaseGroup = dispatch_group_create();

	dispatch_group_enter(waitForDatabaseGroup);


	[self retrieveItemFromDatabaseForFileID:fileID completionHandler:^(NSError *error, OCSyncAnchor syncAnchor, OCItem *itemFromDatabase) {
		item = itemFromDatabase;

		if (outSyncAnchor != NULL)
		{
			*outSyncAnchor = syncAnchor;
		}

		if (outError != NULL)
		{
			*outError = error;
		}

		dispatch_group_leave(waitForDatabaseGroup);
	}];

	dispatch_group_wait(waitForDatabaseGroup, DISPATCH_TIME_FOREVER);
	*/

	return (item);
}

@end
