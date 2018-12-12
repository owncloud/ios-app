//
//  FileProviderExtension.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 07.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <FileProvider/FileProvider.h>
#import <ownCloudSDK/ownCloudSDK.h>

@interface FileProviderExtension : NSFileProviderExtension <OCCoreDelegate, OCLogTagging>
{
	OCCore *_core;
	OCBookmark *_bookmark;
}

@property(strong,nonatomic,readonly) OCCore *core;
@property(strong,nonatomic,readonly) OCBookmark *bookmark;

@end

