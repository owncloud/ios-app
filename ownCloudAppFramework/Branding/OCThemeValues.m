//
//  OCThemeValues.m
//  ownCloudAppFramework
//
//  Created by Matthias Hühne on 08.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCThemeValues.h"

@interface OCThemeValues()
{
	NSDictionary<NSString *, id> *_common;
	NSDictionary<NSString *, id> *_ios;
}

@property(readonly,strong) NSDictionary<NSString *, id> *rawJSON;
@property(weak) OCCore *core;
@property(nonatomic, retain) NSURL *url;

@end

@implementation OCThemeValues

#pragma mark - Common
@dynamic logo;
@dynamic name;
@dynamic slogan;

- (instancetype)initWithURL:(NSURL *)inURL core:(OCCore *)core
{
	if ((self = [super init]) != nil)
	{
		_url = inURL;
		_core = core;
	}

	return (self);
}

#pragma mark - Retrieve theme values
- (NSProgress *)retrieveThemeJSONWithCompletionHandler:(void(^)(NSError * _Nullable error))completionHandler
{
	OCHTTPRequest *request;
	NSProgress *progress = nil;

	if ((request = [OCHTTPRequest requestWithURL:self.url]) != nil)
	{
		progress = [self.core.connection sendRequest:request ephermalCompletionHandler:^(OCHTTPRequest *request, OCHTTPResponse *response, NSError *error) {
			NSData *responseBody = response.bodyData;

			if ((error == nil) && response.status.isSuccess && (responseBody!=nil))
			{
				NSDictionary<NSString *, id> *rawJSON;

				if ((rawJSON = [NSJSONSerialization JSONObjectWithData:responseBody options:0 error:&error]) != nil)
				{
					if ((rawJSON = OCTypedCast(rawJSON, NSDictionary)) != nil)
					{
						self->_rawJSON = rawJSON;
						self->_common = rawJSON[@"common"];
						self->_ios = rawJSON[@"ios"];
					}
					else
					{
						error = OCError(OCErrorResponseUnknownFormat);
					}
				}
			}
			else
			{
				if (error == nil)
				{
					error = response.status.error;
				}
			}
			completionHandler(error);
		}];
	}

	return (progress);
}

- (void)retrieveLogoWithChangeHandler:(OCResourceRequestChangeHandler)changeHandler
{
	OCResourceRequest *iconResourceRequest = [OCResourceRequestURLItem requestURLItem:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", _core.connection.bookmark.url, self.logo]] identifier:nil version:OCResourceRequestURLItem.daySpecificVersion structureDescription:@"icon" waitForConnectivity:YES changeHandler:changeHandler];
	iconResourceRequest.lifetime = OCResourceRequestLifetimeSingleRun;

	OCResourceManager *resourceManager = self.core.vault.resourceManager;
	[resourceManager startRequest:iconResourceRequest];
}

#pragma mark - Common
- (NSString *)logo
{
	return (OCTypedCast(_rawJSON[@"common"][@"logo"], NSString));
}

- (NSString *)name
{
	return (OCTypedCast(_rawJSON[@"common"][@"name"], NSString));
}

- (NSString *)slogan
{
	return (OCTypedCast(_rawJSON[@"common"][@"slogan"], NSString));
}

@end

