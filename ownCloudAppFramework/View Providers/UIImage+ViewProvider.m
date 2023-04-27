//
//  UIImage+ViewProvider.m
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 19.04.23.
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

#import "UIImage+ViewProvider.h"
#import "OCCircularImageView.h"

@implementation UIImage (ViewProvider)

#pragma mark - View provider
- (void)provideViewForSize:(CGSize)size inContext:(OCViewProviderContext *)context completion:(void (^)(UIView * _Nullable))completionHandler
{
	if (((NSNumber *) context.attributes[OCViewProviderContextKeyUseCircular]).boolValue)
	{
		OCCircularImageView *avatarView = nil;

		avatarView = [[OCCircularImageView alloc] initWithImage:self];
		avatarView.translatesAutoresizingMaskIntoConstraints = NO;

		completionHandler(avatarView);
	}
	else
	{
		UIImageView *imageView = [[UIImageView alloc] initWithImage:self];

		imageView.translatesAutoresizingMaskIntoConstraints = NO;

		// Apply content mode
		NSNumber *contentMode;
		if ((contentMode = context.attributes[OCViewProviderContextKeyContentMode]) != nil)
		{
			imageView.contentMode = contentMode.integerValue;
			imageView.clipsToBounds = true;
		}
		else
		{
			imageView.contentMode = UIViewContentModeScaleAspectFit;
		}

		completionHandler(imageView);
	}
}

@end
