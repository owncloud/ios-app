//
//  NSError+MessageResolution.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 09.04.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <ownCloudSDK/ownCloudSDK.h>
#import "NSError+MessageResolution.h"

@implementation NSError (MessageResolution)

- (NSError *)resolvedErrorWithTranslation:(BOOL)withTranslation
{
	if ([self.domain isEqual:OCErrorDomain])
	{
		NSErrorDomain errorDomain = self.domain;
		NSInteger errorCode = self.code;

		NSString *localizedDescription = self.localizedDescription;
		NSString *localizedFailureReason = self.localizedFailureReason;

		NSMutableDictionary *resolvedDict = [NSMutableDictionary new];

		if (localizedDescription != nil)
		{
			resolvedDict[NSLocalizedDescriptionKey] = localizedDescription;
		}

		if (localizedFailureReason != nil)
		{
			resolvedDict[NSLocalizedFailureReasonErrorKey] = localizedFailureReason;
		}

		if (withTranslation)
		{
			errorDomain = NSCocoaErrorDomain;

			resolvedDict[NSUnderlyingErrorKey] = self;

			switch ((OCError)self.code)
			{
				case OCErrorItemAlreadyExists:
					errorCode = NSFileWriteFileExistsError;
				break;

				case OCErrorItemNotFound:
				case OCErrorItemDestinationNotFound:
				case OCErrorFileNotFound:
					errorCode = NSFileNoSuchFileError;
				break;

				case OCErrorFeatureNotImplemented:
				case OCErrorItemOperationForbidden:
					errorCode = NSFeatureUnsupportedError;
				break;

				case OCErrorItemInsufficientPermissions:
					errorCode = NSFileWriteNoPermissionError;
				break;

				case OCErrorCancelled:
					errorCode = NSUserCancelledError;
				break;

				case OCErrorInsufficientStorage:
					errorCode = NSFileWriteOutOfSpaceError;
				break;

				default:
					errorCode = NSFileReadUnknownError;
				break;
			}
		}

		return ([NSError errorWithDomain:errorDomain code:errorCode userInfo:resolvedDict]);
	}

	return (self);
}

- (NSError *)translatedError
{
	if (@available(iOS 13, *))
	{
		return ([self resolvedErrorWithTranslation:YES]);
	}

	return ([self resolvedErrorWithTranslation:NO]);
}

@end
