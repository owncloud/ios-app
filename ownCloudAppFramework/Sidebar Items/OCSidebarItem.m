//
//  OCSidebarItem.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 28.02.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCSidebarItem.h"

@implementation OCSidebarItem

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		_uuid = NSUUID.UUID.UUIDString;
	}

	return (self);
}

- (instancetype)initWithLocation:(OCLocation *)location
{
	if ((self = [self init]) != nil)
	{
		self.location = location;
	}

	return (self);
}

//! MARK: - Data item
- (OCDataItemType)dataItemType
{
	return (OCDataItemTypeSidebarItem);
}

- (OCDataItemReference)dataItemReference
{
	return (_uuid);
}

- (OCDataItemVersion)dataItemVersion
{
	return ([NSString stringWithFormat:@"%@%@", self.uuid, self.location.lastPathComponent]);
}

//! MARK: - Secure coding
+ (BOOL)supportsSecureCoding
{
	return (YES);
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
	[coder encodeObject:_uuid forKey:@"uuid"];
	[coder encodeObject:_location forKey:@"location"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
	if ((self = [self init]) != nil)
	{
		_uuid = [coder decodeObjectOfClass:NSString.class forKey:@"uuid"];
		_location = [coder decodeObjectOfClass:OCLocation.class forKey:@"location"];
	}

	return (self);
}

//! MARK: - Comparison
- (NSUInteger)hash
{
	return (_uuid.hash ^ _location.hash);
}

- (BOOL)isEqual:(id)object
{
	OCSidebarItem *otherSidebarItem;

	if ((otherSidebarItem = OCTypedCast(object, OCSidebarItem)) != nil)
	{
		return (OCNAIsEqual(otherSidebarItem.uuid, _uuid) &&
			OCNAIsEqual(otherSidebarItem.location, _location)
		);
	}

	return (NO);
}

@end

OCDataItemType OCDataItemTypeSidebarItem = @"sidebarItem";
