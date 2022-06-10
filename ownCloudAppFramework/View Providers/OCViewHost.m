//
//  OCViewHost.m
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

#import "OCViewHost.h"

@interface OCViewHost ()
{
	UIView *_hostedView;
	NSUInteger _requestSeed;
}
@end

@implementation OCViewHost

- (instancetype)initWithFallbackSize:(CGSize)fallbackSize
{
	if ((self = [super init]) != nil)
	{
		_fallbackSize = fallbackSize;
	}

	return (self);
}

- (instancetype)initWithFallbackView:(UIView *)fallbackView viewProviderContext:(nullable OCViewProviderContext *)viewProviderContext
{
	if ((self = [super init]) != nil)
	{
		_viewProviderContext = viewProviderContext;
		self.fallbackView = fallbackView;
	}

	return (self);
}

- (instancetype)initWithRequest:(OCResourceRequest *)request fallbackView:(UIView *)fallbackView viewProviderContext:(OCViewProviderContext *)viewProviderContext;
{
	if ((self = [super init]) != nil)
	{
		_fallbackSize = request.maxPointSize;
		_viewProviderContext = viewProviderContext;
		_fallbackView = fallbackView;
		self.request = request;
	}

	return (self);
}

- (instancetype)initWithViewProvider:(id<OCViewProvider>)viewProvider fallbackSize:(CGSize)fallbackSize fallbackView:(UIView *)fallbackView viewProviderContext:(OCViewProviderContext *)viewProviderContext
{
	if ((self = [super init]) != nil)
	{
		_viewProviderContext = viewProviderContext;
		_fallbackView = fallbackView;
		_fallbackSize = fallbackSize;
		self.activeViewProvider = viewProvider;
	}

	return (self);
}

#pragma mark - Resource requests
- (void)setRequest:(OCResourceRequest *)request
{
	_request.delegate = nil;

	_request = request;
	_request.delegate = self;

	_requestSeed++;

	[self setActiveViewProviderFromResource:_request.resource];
}

- (void)resourceRequest:(nonnull OCResourceRequest *)request didChangeWithError:(nullable NSError *)error isOngoing:(BOOL)isOngoing previousResource:(nullable OCResource *)previousResource newResource:(nullable OCResource *)newResource
{
	if (request != self->_request)
	{
		OCLogDebug(@"Delayed request update received");
		return;
	}

	if ((error == nil) && ((newResource != nil) || !isOngoing))
	{
		NSUInteger requestSeedOnDelivery = _requestSeed;

		[self onMainThread:^{
			if ((request == self->_request) || // same request
			    ((self->_request == nil) && (requestSeedOnDelivery == self->_requestSeed))) // request is no longer ongoing, but no new request has been set in the meantime, either, so this resource can be used
			{
				if (newResource != nil)
				{
					[self setActiveViewProviderFromResource:newResource];
				}
				else
				{
					self.activeViewProvider = nil;
				}
			}
		}];
	}

	if (!isOngoing)
	{
		_request.delegate = nil;
		_request = nil;
	}
}

#pragma mark - View Provider Context
- (void)setViewProviderContext:(OCViewProviderContext *)viewProviderContext
{
	_viewProviderContext = viewProviderContext;
	[self updateView];
}

#pragma mark - Active view provider
- (void)setActiveViewProviderFromResource:(OCResource *)resource
{
	id<OCViewProvider> newViewProvider;

	if ((newViewProvider = OCConformanceCast(resource, OCViewProvider)) != nil)
	{
		if (_activeViewProvider != newViewProvider)
		{
			self.activeViewProvider = newViewProvider;
		}
	}
}

- (void)setActiveViewProvider:(id<OCViewProvider>)activeViewProvider
{
	_activeViewProvider = activeViewProvider;
	[self updateView];
}

#pragma mark - Fallback view
- (void)setFallbackView:(UIView *)fallbackView
{
	_fallbackView = fallbackView;
	[self updateView];
}

#pragma mark - Update views
- (void)setHostedView:(UIView *)newView
{
	if (newView != _hostedView)
	{
		[self willChangeValueForKey:@"contentStatus"];

		[_hostedView removeFromSuperview];
		_hostedView = newView;

		newView.translatesAutoresizingMaskIntoConstraints = NO;

		if (newView != nil)
		{
			[self addSubview:newView];

			[self addConstraints:@[
				[newView.leftAnchor 	constraintEqualToAnchor:self.leftAnchor],
				[newView.rightAnchor 	constraintEqualToAnchor:self.rightAnchor],
				[newView.topAnchor 	constraintEqualToAnchor:self.topAnchor],
				[newView.bottomAnchor 	constraintEqualToAnchor:self.bottomAnchor]
			]];
		}

		[self didChangeValueForKey:@"contentStatus"];
	}
}

- (void)onMainThread:(dispatch_block_t)block
{
	if (NSThread.isMainThread)
	{
		block();
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), block);
	}
}

- (void)updateView
{
	id<OCViewProvider> originalViewProvider = _activeViewProvider;

	if (_activeViewProvider != nil)
	{
		CGSize size = self.frame.size;

		if ((size.width == 0) || (size.height == 0))
		{
			size = _fallbackSize;
		}

		[_activeViewProvider provideViewForSize:size inContext:self.viewProviderContext completion:^(UIView * _Nullable newView) {
			[self onMainThread:^{
				if (originalViewProvider == self.activeViewProvider) {
					[self setHostedView:(newView != nil) ? newView : self.fallbackView];
					// OCLogDebug(@"%p: _activeViewProvider/originalViewProvider: %@, size: %@, newView: %@", self, originalViewProvider, NSStringFromCGSize(size), newView);
				} else {
					OCLogWarning(@"%p: _activeViewProvider changed during receipt (from %@ to %@)", self, originalViewProvider, self.activeViewProvider);
				}
			}];
		}];
	}
	else
	{
		[self onMainThread:^{
			if (originalViewProvider == self.activeViewProvider) {
				 // OCLogDebug(@"%p: _activeViewProvider/originalViewProvider: %@, size: %@, newView: %@", self, originalViewProvider, NSStringFromCGSize(size), self.fallbackView);
				[self setHostedView:self.fallbackView];
			} else {
				OCLogWarning(@"%p: _activeViewProvider changed during receipt (from %@ to %@)", self, originalViewProvider, self.activeViewProvider);
			}
		}];
	}
}

- (void)reloadView
{
	[self updateView];
}

- (OCViewHostContentStatus)contentStatus
{
	if (_hostedView == nil)
	{
		return (OCViewHostContentStatusNone);
	}

	if (_hostedView == _fallbackView)
	{
		return (OCViewHostContentStatusFallback);
	}

	return (OCViewHostContentStatusFromResource);
}

@end
