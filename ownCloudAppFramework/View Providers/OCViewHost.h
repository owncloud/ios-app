//
//  OCViewHost.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 18.01.22.
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

#import <UIKit/UIKit.h>
#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OCViewHostContentStatus) {
	OCViewHostContentStatusNone,
	OCViewHostContentStatusFallback,
	OCViewHostContentStatusFromResource
};

@interface OCViewHost : UIView <OCResourceRequestDelegate>

@property(readonly,nonatomic) OCViewHostContentStatus contentStatus;

@property(strong,nullable,nonatomic) OCViewProviderContext *viewProviderContext;

@property(strong,nullable,nonatomic) OCResourceRequest *request;
@property(strong,nullable,nonatomic) id<OCViewProvider> activeViewProvider;

@property(strong,nullable,nonatomic) UIView *fallbackView;
@property(assign) CGSize fallbackSize;

- (instancetype)initWithFallbackSize:(CGSize)fallbackSize;
- (instancetype)initWithFallbackView:(UIView *)fallbackView viewProviderContext:(nullable OCViewProviderContext *)viewProviderContext;

- (instancetype)initWithRequest:(OCResourceRequest *)request fallbackView:(nullable UIView *)fallbackView viewProviderContext:(nullable OCViewProviderContext *)viewProviderContext;
- (instancetype)initWithViewProvider:(id<OCViewProvider>)viewProvider fallbackSize:(CGSize)fallbackSize fallbackView:(nullable UIView *)fallbackView viewProviderContext:(nullable OCViewProviderContext *)viewProviderContext;

- (void)reloadView;

@end

NS_ASSUME_NONNULL_END
