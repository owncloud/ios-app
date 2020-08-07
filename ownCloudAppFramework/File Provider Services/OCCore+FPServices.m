//
//  OCCore+FPServices.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 22.07.20.
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
#import "OCCore+FPServices.h"
#import "OCBookmark+FPServices.h"
#import "OCVault+FPServices.h"
#import "OCFileProviderService.h"
#import "OCFileProviderServiceSession.h"

#import <objc/runtime.h>

static NSString *sOCCoreFPServiceSessionKey = @"sOCCoreFPServiceSessionKey";

@implementation OCCore (FPServices)

- (void)acquireFileProviderServicesHostWithCompletionHandler:(void(^)(NSError * _Nullable error, id<OCFileProviderServicesHost> _Nullable, void(^ _Nullable doneHandler)(void)))completionHandler errorHandler:(void(^)(NSError *error))errorHandler
{
	OCFileProviderServiceSession *session;

	@synchronized(sOCCoreFPServiceSessionKey)
	{
		if ((session = objc_getAssociatedObject(self, (__bridge void *)sOCCoreFPServiceSessionKey)) == nil)
		{
			if ((session = [[OCFileProviderServiceSession alloc] initWithServiceURL:self.vault.fpServicesURL]) != nil)
			{
				objc_setAssociatedObject(self, (__bridge void *)sOCCoreFPServiceSessionKey, session, OBJC_ASSOCIATION_RETAIN);
			}
		}
	}

	[session acquireFileProviderServicesHostWithCompletionHandler:completionHandler errorHandler:errorHandler];
}

@end
