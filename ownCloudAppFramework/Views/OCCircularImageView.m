//
//  OCCircularImageView.m
//  ownCloud
//
//  Created by Felix Schwarz on 19.01.22.
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

#import "OCCircularImageView.h"

@implementation OCCircularImageView

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		self.opaque = NO;
	}

	return (self);
}

- (instancetype)initWithImage:(nullable UIImage *)image
{
	if ((self = [self init]) != nil)
	{
		_image = image;
	}

	return (self);
}

- (void)setImage:(UIImage *)image
{
	_image = image;
	[self setNeedsDisplay];
}

- (CGSize)circularContentSizeForSize:(CGSize)size
{
	return (_image.size);
}

- (void)drawContentInRect:(CGRect)rect circularSize:(CGSize)size
{
	[_image drawInRect:rect];
}

@end
