//
//  OCLicenseEnvironment.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 29.10.19.
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

#import "OCLicenseEnvironment.h"

@implementation OCLicenseEnvironment

+ (instancetype)environmentWithIdentifier:(nullable OCLicenseEnvironmentIdentifier)identifier hostname:(nullable NSString *)hostname certificate:(nullable OCCertificate *)certificate attributes:(NSDictionary<OCLicenseEnvironmentAttributesKey, id> *)attributes
{
	OCLicenseEnvironment *environment = [self new];

	environment.identifier = identifier;
	environment.hostname = hostname;
	environment.certificate = certificate;
	environment.attributes = attributes;

	return (environment);
}

+ (instancetype)environmentWithBookmark:(OCBookmark *)bookmark
{
	OCLicenseEnvironment *environment = [self new];

	environment.identifier = bookmark.uuid.UUIDString;
	environment.bookmarkUUID = bookmark.uuid;
	environment.bookmark = bookmark;
	environment.hostname = bookmark.url.host;
	environment.certificate = bookmark.certificate;

	return (environment);
}

- (OCBookmarkUUID)bookmarkUUID
{
	if (_bookmarkUUID == nil)
	{
		if (_bookmark.uuid != nil)
		{
			return (_bookmark.uuid);
		}

		if (_core.bookmark.uuid != nil)
		{
			return (_core.bookmark.uuid);
		}
	}

	return (_bookmarkUUID);
}

- (OCBookmark *)bookmark
{
	if (_bookmark == nil)
	{
		if (_core.bookmark != nil)
		{
			return (_core.bookmark);
		}

		if (_bookmarkUUID != nil)
		{
			return ([OCBookmarkManager.sharedBookmarkManager bookmarkForUUID:_bookmarkUUID]);
		}
	}

	return (_bookmark);
}

@end
