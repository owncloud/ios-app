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
#import <ownCloudApp/OCBookmark+AppExtensions.h>
#import <ownCloudApp/NSObject+AnnotatedProperties.h>
#import <ownCloudApp/NSDate+RFC3339.h>
#import <ownCloudApp/ZIPArchive.h>

#import <ownCloudApp/OCBookmark+FPServices.h>
#import <ownCloudApp/OCVault+FPServices.h>
#import <ownCloudApp/OCCore+FPServices.h>
#import <ownCloudApp/OCFileProviderService.h>
#import <ownCloudApp/OCFileProviderServiceSession.h>
#import <ownCloudApp/OCFileProviderServiceStandby.h>

#import <ownCloudApp/OCLicenseTypes.h>
#import <ownCloudApp/OCLicenseManager.h>
#import <ownCloudApp/OCLicenseObserver.h>

#import <ownCloudApp/OCLicenseFeature.h>
#import <ownCloudApp/OCLicenseProduct.h>

#import <ownCloudApp/OCLicenseProvider.h>
#import <ownCloudApp/OCLicenseEntitlement.h>
#import <ownCloudApp/OCLicenseOffer.h>
#import <ownCloudApp/OCLicenseDuration.h>
#import <ownCloudApp/OCLicenseTransaction.h>

#import <ownCloudApp/OCLicenseAppStoreProvider.h>
#import <ownCloudApp/OCLicenseAppStoreItem.h>
#import <ownCloudApp/OCLicenseAppStoreReceipt.h>
#import <ownCloudApp/OCLicenseAppStoreReceiptInAppPurchase.h>

#import <ownCloudApp/OCLicenseEnterpriseProvider.h>

#import <ownCloudApp/OCLicenseEMMProvider.h>

#import <ownCloudApp/OCLicenseEnvironment.h>
#import <ownCloudApp/OCCore+LicenseEnvironment.h>

#import <ownCloudApp/NotificationManager.h>
#import <ownCloudApp/NotificationMessagePresenter.h>
#import <ownCloudApp/NotificationAuthErrorForwarder.h>

#import <ownCloudApp/Branding.h>
