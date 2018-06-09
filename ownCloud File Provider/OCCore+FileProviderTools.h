//
//  OCCore+FileProviderTools.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import <ownCloudSDK/ownCloudSDK.h>

@interface OCCore (FileProviderTools)

- (OCItem *)synchronousRetrieveItemFromDatabaseForFileID:(OCFileID)fileID syncAnchor:(OCSyncAnchor __autoreleasing *)outSyncAnchor error:(NSError * __autoreleasing *)outError;

@end
