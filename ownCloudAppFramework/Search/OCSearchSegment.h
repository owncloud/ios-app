//
//  OCSearchSegment.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 22.08.22.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCSearchSegment : NSObject

@property(assign) NSRange range; //!< The range of the segment within the search term it was extracted from.
@property(assign) BOOL hasCursor; //!< YES if the cursor is currently placed at the end or inside this segment.

@property(strong) NSString *originalString; //!< Original segment string, before normalization.
@property(assign) NSInteger cursorOffset; //!< If .hasCursor is YES, the position of the cursor within the originalString. -1 otherwise.

@property(strong) NSString *segmentedString; //!< The normalized string of this segment.

@end

NS_ASSUME_NONNULL_END
