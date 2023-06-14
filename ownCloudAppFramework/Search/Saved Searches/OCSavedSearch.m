//
//  OCSavedSearch.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 13.09.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCSavedSearch.h"

@implementation OCSavedSearch

- (instancetype)initWithScope:(OCSavedSearchScope)scope location:(nullable OCLocation *)location name:(nullable NSString *)name isTemplate:(BOOL)isTemplate searchTerm:(NSString *)searchTerm userInfo:(nullable NSDictionary<OCSavedSearchUserInfoKey, id> *)userInfo
{
	if ((self = [super init]) != nil)
	{
		_uuid = NSUUID.UUID.UUIDString;
		_scope = scope;
		_isTemplate = isTemplate;
		_location = location;
		_name = name;
		_searchTerm = searchTerm;
		_userInfo = userInfo;
	}

	return (self);
}

- (NSString *)name
{
	return ((_name != nil) ? _name : _searchTerm);
}

- (BOOL)isNameUserDefined
{
	return (_name != nil);
}

#pragma mark - Data item & Data item versioning
- (OCDataItemType)dataItemType
{
	return (OCDataItemTypeSavedSearch);
}

- (OCDataItemReference)dataItemReference
{
	return (_uuid);
}

- (OCDataItemVersion)dataItemVersion
{
	return (@(self.hash));
}

#pragma mark - Comparison
- (NSUInteger)hash
{
	return (_uuid.hash ^ _scope.hash ^ _location.hash ^ _name.hash ^ _searchTerm.hash ^ _userInfo.hash ^ (_isTemplate ? 0xFEA43 : 0));
}

- (BOOL)isEqual:(id)object
{
	OCSavedSearch *otherSavedSearch;

	if ((otherSavedSearch = OCTypedCast(object, OCSavedSearch)) != nil)
	{
		return (OCNAIsEqual(otherSavedSearch.uuid, _uuid) &&
			OCNAIsEqual(otherSavedSearch.scope, _scope) &&
			OCNAIsEqual(otherSavedSearch.location, _location) &&
			OCNAIsEqual(otherSavedSearch.name, self.name) &&
			OCNAIsEqual(otherSavedSearch.searchTerm, _searchTerm) &&
			OCNAIsEqual(otherSavedSearch.userInfo, _userInfo) &&
			otherSavedSearch.isTemplate == _isTemplate
		);
	}

	return (NO);
}

#pragma mark - Secure coding
+ (BOOL)supportsSecureCoding
{
	return (YES);
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
	[coder encodeObject:_uuid forKey:@"uuid"];

	[coder encodeBool:_isTemplate forKey:@"isTemplate"];

	[coder encodeObject:_scope forKey:@"scope"];

	[coder encodeObject:_location forKey:@"location"];

	[coder encodeObject:_name forKey:@"name"];
	[coder encodeObject:_searchTerm forKey:@"searchTerm"];

	[coder encodeObject:_userInfo forKey:@"userInfo"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
	if ((self = [self init]) != nil)
	{
		_uuid = [coder decodeObjectOfClass:NSString.class forKey:@"uuid"];

		_isTemplate = [coder decodeBoolForKey:@"isTemplate"];

		_scope = [coder decodeObjectOfClass:NSString.class forKey:@"scope"];

		_location = [coder decodeObjectOfClass:OCLocation.class forKey:@"location"];

		_name = [coder decodeObjectOfClass:NSString.class forKey:@"name"];
		_searchTerm = [coder decodeObjectOfClass:NSString.class forKey:@"searchTerm"];

		_userInfo = [coder decodeObjectOfClasses:OCEvent.safeClasses forKey:@"userInfo"];
	}

	return (self);
}

@end

OCSavedSearchScope OCSavedSearchScopeFolder = @"folder";
OCSavedSearchScope OCSavedSearchScopeContainer = @"container";
OCSavedSearchScope OCSavedSearchScopeDrive = @"drive";
OCSavedSearchScope OCSavedSearchScopeAccount = @"account";
