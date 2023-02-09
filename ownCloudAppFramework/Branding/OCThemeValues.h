//
//  OCThemeValues.h
//  ownCloudSDK
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

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCThemeValues : NSObject

#pragma mark - Common
@property(readonly,nullable,nonatomic) NSString *logo;
@property(readonly,nullable,nonatomic) NSString *name;
@property(readonly,nullable,nonatomic) NSString *slogan;

- (instancetype)initWithURL:(NSURL *)inURL core:(OCCore *)core;
- (NSProgress *)retrieveThemeJSONWithCompletionHandler:(void(^)(NSError * _Nullable error))completionHandler;
- (void)retrieveLogoWithChangeHandler:(OCResourceRequestChangeHandler)changeHandler;

@end

NS_ASSUME_NONNULL_END
