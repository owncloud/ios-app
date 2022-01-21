//
//  OCCircularContentView.m
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

#import "OCCircularContentView.h"

@implementation OCCircularContentView

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		self.opaque = NO;
	}

	return (self);
}

- (void)drawRect:(CGRect)rect
{
	CGSize viewSize = self.bounds.size;
	CGFloat sideLength = (viewSize.width > viewSize.height) ? viewSize.height : viewSize.width;
	CGSize circularSize = CGSizeMake(sideLength, sideLength);
	CGSize contentSize = [self circularContentSizeForSize:circularSize], renderSize;

	CGContextRef contextRef = UIGraphicsGetCurrentContext();
	UIBezierPath *clipPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake((viewSize.width - sideLength) / 2.0, (viewSize.height - sideLength) / 2.0, sideLength, sideLength)];

	if (contentSize.width > contentSize.height)
	{
		renderSize.height = sideLength;
		renderSize.width = (contentSize.width * sideLength) / contentSize.height;
	}
	else
	{
		renderSize.width = sideLength;
		renderSize.height = (contentSize.height * sideLength) / contentSize.width;
	}

	CGContextSaveGState(contextRef);

	[clipPath addClip];
	[self drawContentInRect:CGRectMake((viewSize.width - renderSize.width) / 2.0, (viewSize.height - renderSize.height) / 2.0, renderSize.width, renderSize.height) circularSize:circularSize];

	CGContextRestoreGState(contextRef);
}

- (CGSize)circularContentSizeForSize:(CGSize)size
{
	return (CGSizeMake(0, 0));
}

- (void)drawContentInRect:(CGRect)rect circularSize:(CGSize)size
{

}

@end
