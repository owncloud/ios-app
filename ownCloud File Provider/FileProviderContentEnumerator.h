//
//  FileProviderContentEnumerator.h
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 05.05.22.
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
#import <ownCloudSDK/ownCloudSDK.h>
#import "FileProviderEnumeratorObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileProviderContentEnumerator : NSObject <NSFileProviderEnumerator, OCQueryDelegate>
{
	NSMutableArray <FileProviderEnumeratorObserver *> *_enumerationObservers;
	NSMutableArray <FileProviderEnumeratorObserver *> *_changeObservers;
}

@property(nonatomic,readonly,class) OCAsyncSequentialQueue *queue;

@property(strong) OCVFSCore *vfsCore;
@property(strong) OCVFSItemID containerItemIdentifier;

@property(strong,nullable,nonatomic) OCVFSContent *content;

- (instancetype)initWithVFSCore:(OCVFSCore *)vfsCore containerItemIdentifier:(OCVFSItemID)containerItemIdentifier;

@end

NS_ASSUME_NONNULL_END
