//
//  OCSearchSegment.m
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

#import "OCSearchSegment.h"
#import <ownCloudSDK/ownCloudSDK.h>

@implementation OCSearchSegment

#pragma mark - Description
- (NSString *)description
{
	return ([NSString stringWithFormat:@"<%@: %p%@%@ hasCursor: %d, cursorOffset: %ld, range: %@>", NSStringFromClass(self.class), self,
		OCExpandVar(originalString),
		OCExpandVar(segmentedString),
		_hasCursor,
		_cursorOffset,
		NSStringFromRange(_range)
	]);
}

@end
