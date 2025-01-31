//
//  NSURL+OCVaultTools.m
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "NSURL+OCVaultTools.h"

@implementation NSURL (OCVaultTools)

- (BOOL)isLocatedWithinVaultStorage
{
	if (!self.isFileURL)
	{
		return (NO);
	}

	NSString *vaultRootPath = OCVault.storageRootURL.path;
	NSString *path = self.path;

	if (![vaultRootPath hasSuffix:@"/"])
	{
		vaultRootPath = [vaultRootPath stringByAppendingString:@"/"];
	}

	return ([path hasPrefix:vaultRootPath]);
}

- (BOOL)isLocalFile
{
	NSURLFileResourceType resourceType = nil;
	NSError *error = nil;

	if (self.isFileURL && [self getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:&error])
	{
		return ([resourceType isEqual:NSURLFileResourceTypeRegular]);
	}

	return (NO);
}

@end
