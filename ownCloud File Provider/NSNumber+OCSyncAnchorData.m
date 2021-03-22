//
//  NSNumber+OCSyncAnchorData.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 18.07.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "NSNumber+OCSyncAnchorData.h"
#import <ownCloudSDK/ownCloudSDK.h>

@implementation NSNumber (OCSyncAnchorData)

+ (instancetype)numberFromSyncAnchorData:(NSFileProviderSyncAnchor)syncAnchor
{
	NSNumber *syncAnchorNumber = nil;
	if (syncAnchor != nil)
	{
		NSError *error = nil;

		if ((syncAnchorNumber = [NSKeyedUnarchiver unarchivedObjectOfClass:NSNumber.class fromData:syncAnchor error:&error]) == nil)
		{
			OCLogError(@"Error decoding sync anchor number: %@", error);
		}
	}

	return (syncAnchorNumber);
}

- (NSFileProviderSyncAnchor)syncAnchorData
{
	NSData *syncAnchorData = nil;
	NSError *error = nil;

	if ((syncAnchorData = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:YES error:&error]) == nil)
	{
		OCLogError(@"Error encoding sync anchor number: %@", error);
	}

	return (syncAnchorData);
}

@end
