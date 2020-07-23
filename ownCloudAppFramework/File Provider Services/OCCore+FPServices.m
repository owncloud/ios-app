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

@implementation OCCore (FPServices)

- (void)acquireFileProviderServicesHostWithCompletionHandler:(void(^)(NSError * _Nullable error, id<OCFileProviderServicesHost> _Nullable, void(^ _Nullable doneHandler)(void)))completionHandler
{
	[NSFileManager.defaultManager getFileProviderServicesForItemAtURL:self.vault.fpServicesURL completionHandler:^(NSDictionary<NSFileProviderServiceName,NSFileProviderService *> * _Nullable services, NSError * _Nullable error) {
		NSFileProviderService *service;

		if ((service = services[OCFileProviderServiceName]) != nil)
		{
			[service getFileProviderConnectionWithCompletionHandler:^(NSXPCConnection * _Nullable connection, NSError * _Nullable error) {
				if (error == nil)
				{
					__weak NSXPCConnection *weakConnection = connection;

					connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(OCFileProviderServicesHost)];
					connection.interruptionHandler = ^{
						[weakConnection invalidate];
					};
					[connection resume];
				}

				id<OCFileProviderServicesHost> remoteObjectProxy = [connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
					OCLogError(@"File Provider Services proxy connection error: %@", error);
				}];

				completionHandler(error, (id<OCFileProviderServicesHost>)remoteObjectProxy, ^{
					[connection invalidate];
				});
			}];
		}
	}];
}

@end
