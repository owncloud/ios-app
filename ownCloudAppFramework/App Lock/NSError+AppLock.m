//
//  NSError+AppLock.m
//  ownCloud
//
//  Created by Felix Schwarz on 26.06.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

#import "NSError+AppLock.h"

@implementation NSError (AppLock)

+ (instancetype)errorWithAppLockError:(AppLockError)errorCode userInfo:(nullable NSDictionary<NSErrorUserInfoKey,id> *)userInfo
{
	return ([NSError errorWithDomain:AppLockErrorDomain code:errorCode userInfo:userInfo]);
}

+ (instancetype)errorWithAppLockError:(AppLockError)errorCode
{
	return ([NSError errorWithDomain:AppLockErrorDomain code:errorCode userInfo:nil]);
}

- (BOOL)isAppLockError
{
	return ([self.domain isEqual:AppLockErrorDomain]);
}

- (BOOL)isAppLockErrorWithCode:(AppLockError)errorCode
{
	return ([self.domain isEqual:AppLockErrorDomain] && (self.code == errorCode));
}

@end

NSErrorDomain AppLockErrorDomain = @"AppLockError";
