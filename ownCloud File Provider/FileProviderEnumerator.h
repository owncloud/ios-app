//
//  FileProviderEnumerator.h
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
#import "FileProviderEnumeratorObserver.h"

@class FileProviderExtension;

@interface FileProviderEnumerator : NSObject <NSFileProviderEnumerator, OCQueryDelegate, OCLogTagging>
{
	__weak FileProviderExtension *_fileProviderExtension;

	OCCore *_core;
	OCBookmark *_bookmark;
	NSFileProviderItemIdentifier _enumeratedItemIdentifier;

	OCQuery *_query;

	NSMutableArray <FileProviderEnumeratorObserver *> *_enumerationObservers;
	NSMutableArray <FileProviderEnumeratorObserver *> *_changeObservers;

	BOOL _invalidated;
}

@property(weak) FileProviderExtension *fileProviderExtension;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBookmark:(OCBookmark *)bookmark enumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier;

@property (nonatomic, readonly, strong) NSFileProviderItemIdentifier enumeratedItemIdentifier;

@end
