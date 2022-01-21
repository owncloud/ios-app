//
//  OCCircularTextView.m
//  ownCloudApp
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

#import "OCCircularTextView.h"

@interface OCCircularTextView ()
{
	CGSize _textSize;
}
@end

@implementation OCCircularTextView

- (void)setText:(NSString *)text
{
	_text = text;
	[self setNeedsDisplay];
}

- (UIFont *)fontForSize:(CGSize)size
{
	return ([UIFont systemFontOfSize:(size.height / 2.0) weight:UIFontWeightSemibold]);
}

- (CGSize)circularContentSizeForSize:(CGSize)size
{
	CGRect boundingRect = [self.text boundingRectWithSize:size options:0 attributes:@{
		NSFontAttributeName : [self fontForSize:size],
	} context:nil];

	_textSize = CGRectStandardize(boundingRect).size;

	return (_textSize);
}

- (void)drawContentInRect:(CGRect)rect circularSize:(CGSize)size
{
	CGRect viewBounds = self.bounds;

	[[UIColor grayColor] setFill];
	UIRectFill(rect);

	[self.text drawAtPoint:CGPointMake((viewBounds.size.width - _textSize.width) / 2.0, (viewBounds.size.height - _textSize.height) / 2.0) withAttributes:@{
		NSFontAttributeName : [self fontForSize:size],
		NSForegroundColorAttributeName : UIColor.whiteColor
	}];
}

@end
