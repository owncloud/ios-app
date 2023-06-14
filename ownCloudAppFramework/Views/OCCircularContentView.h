//
//  OCCircularContentView.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCCircularContentView : UIView

- (CGSize)circularContentSizeForSize:(CGSize)size;
- (void)drawContentInRect:(CGRect)rect circularSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
