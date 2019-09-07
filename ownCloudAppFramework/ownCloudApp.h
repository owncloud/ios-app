//
//  ownCloudApp.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 21.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <UIKit/UIKit.h>
#import "DisplaySettings.h"

//! Project version number for ownCloudApp.
FOUNDATION_EXPORT double ownCloudAppVersionNumber;

//! Project version string for ownCloudApp.
FOUNDATION_EXPORT const unsigned char ownCloudAppVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ownCloudApp/PublicHeader.h>
#import <ownCloudApp/DisplaySettings.h>
#import <ownCloudApp/NSData+Encoding.h>
#import <ownCloudApp/OCCore+BundleImport.h>
#import <ownCloudApp/ZIPArchive.h>
