//
//  NSError+AppLock.h
//  ownCloud
//
//  Created by Felix Schwarz on 26.06.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AppLockError)
{
	AppLockErrorActivePenalty, //!< Unlock possible due to active time penalty.
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (AppLockError)

+ (instancetype)errorWithAppLockError:(AppLockError)errorCode;
+ (instancetype)errorWithAppLockError:(AppLockError)errorCode userInfo:(nullable NSDictionary<NSErrorUserInfoKey,id> *)userInfo;

- (BOOL)isAppLockError;

- (BOOL)isAppLockErrorWithCode:(AppLockError)errorCode;

@end

extern NSErrorDomain AppLockErrorDomain;

#define AppLockError(errorCode) [NSError errorWithAppLockError:errorCode userInfo:@{ NSDebugDescriptionErrorKey : [NSString stringWithFormat:@"%s [%@:%d]", __PRETTY_FUNCTION__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__] }] //!< Macro that creates an AppLockError from an AppLockError, but also adds method name, source file and line number)

NS_ASSUME_NONNULL_END


