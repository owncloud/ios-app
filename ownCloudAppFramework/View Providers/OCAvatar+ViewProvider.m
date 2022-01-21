//
//  OCAvatar+ViewProvider.m
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

#import "OCAvatar+ViewProvider.h"
#import "OCCircularImageView.h"

@implementation OCAvatar (ViewProvider)

- (void)provideViewForSize:(CGSize)size inContext:(nullable OCViewProviderContext *)context completion:(void(^)(OCView * _Nullable view))completionHandler
{
	[self requestImageForSize:size scale:0 withCompletionHandler:^(OCImage * _Nullable ocImage, NSError * _Nullable error, CGSize maximumSizeInPoints, UIImage * _Nullable image) {
		if (image != nil)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				OCCircularImageView *avatarView = nil;

				avatarView = [[OCCircularImageView alloc] initWithImage:image];
				avatarView.translatesAutoresizingMaskIntoConstraints = NO;

				completionHandler(avatarView);
			});
		}

		completionHandler(nil);
	}];
}

@end
