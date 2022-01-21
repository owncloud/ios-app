//
//  OCResourceTextPlaceholder+ViewProvider.m
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

#import "OCResourceTextPlaceholder+ViewProvider.h"
#import "OCCircularTextView.h"

@implementation OCResourceTextPlaceholder (ViewProvider)

- (void)provideViewForSize:(CGSize)size inContext:(nullable OCViewProviderContext *)context completion:(void(^)(OCView * _Nullable view))completionHandler
{
	if (self.text.length > 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			OCCircularTextView *circularTextView = [OCCircularTextView new];

			circularTextView.translatesAutoresizingMaskIntoConstraints = NO;
			circularTextView.text = self.text;

			completionHandler(circularTextView);
		});
	}
	else
	{
		completionHandler(nil);
	}
}

@end
