//
//  OCLicenseAppStoreReceipt.h
//  ownCloud
//
//  Created by Felix Schwarz on 28.11.19.
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

#import <Foundation/Foundation.h>
#import "OCLicenseAppStoreItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OCLicenseAppStoreReceiptParseError)
{
	OCLicenseAppStoreReceiptParseErrorNone,
	
	OCLicenseAppStoreReceiptParseErrorNoReceipt,
	OCLicenseAppStoreReceiptParseErrorNoRootCA,
	OCLicenseAppStoreReceiptParseErrorNoDeviceID,

	OCLicenseAppStoreReceiptParseErrorPKCS7Decode,
	OCLicenseAppStoreReceiptParseErrorPKCS7Unsigned,
	OCLicenseAppStoreReceiptParseErrorPKCS7ContentsNotData,

	OCLicenseAppStoreReceiptParseErrorX509Store,
	OCLicenseAppStoreReceiptParseErrorX509Certificate,

	OCLicenseAppStoreReceiptParseErrorSignatureVerification,

	OCLicenseAppStoreReceiptParseErrorASN1NotASet,
	OCLicenseAppStoreReceiptParseErrorASN1UnexpectedType
};

typedef NS_ENUM(NSInteger, OCLicenseAppStoreReceiptFieldType)
{
	// Reference: https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1

	// App Receipt Fields
	OCLicenseAppStoreReceiptFieldTypeAppBundleIdentifier 	= 2,  // "bundle_id"
	OCLicenseAppStoreReceiptFieldTypeAppVersion 		= 3,  // "application_version"
	OCLicenseAppStoreReceiptFieldTypeOpaqueValue 		= 4,  // An opaque value used, with other data, to compute the SHA-1 hash during validation.
	OCLicenseAppStoreReceiptFieldTypeSHA1Hash 		= 5,  // A SHA-1 hash, used to validate the receipt.
	OCLicenseAppStoreReceiptFieldTypeReceiptCreationDate	= 12, // "receipt_creation_date"
	OCLicenseAppStoreReceiptFieldTypeInAppPurchase 		= 17, // "in_app" / SET of in-app purchase receipt attributes
	OCLicenseAppStoreReceiptFieldTypeAppOriginalVersion	= 19, // "original_application_version"
	OCLicenseAppStoreReceiptFieldTypeReceiptExpirationDate	= 21, // "expiration_date"

	// In-App Purchase Receipt Fields
	OCLicenseAppStoreReceiptFieldTypeIAPQuantity				= 1701,
	OCLicenseAppStoreReceiptFieldTypeIAPProductID				= 1702,
	OCLicenseAppStoreReceiptFieldTypeIAPTransactionID			= 1703,
	OCLicenseAppStoreReceiptFieldTypeIAPPurchaseDate			= 1704,
	OCLicenseAppStoreReceiptFieldTypeIAPOriginalTransactionID		= 1705,
	OCLicenseAppStoreReceiptFieldTypeIAPOriginalPurchaseDate		= 1706,
	OCLicenseAppStoreReceiptFieldTypeIAPSubscriptionExpirationDate		= 1708,
	OCLicenseAppStoreReceiptFieldTypeIAPWebOrderLineItemID			= 1711,
	OCLicenseAppStoreReceiptFieldTypeIAPCancellationDate			= 1712,
	OCLicenseAppStoreReceiptFieldTypeIAPSubscriptionInIntroOfferPeriod	= 1719
};

typedef NSString* OCLicenseAppStoreTransactionID;
typedef NSNumber* OCLicenseAppStoreLineItemID;

@class OCLicenseAppStoreReceiptInAppPurchase;

@interface OCLicenseAppStoreReceipt : NSObject

#pragma mark - Certificate and device identity data
@property(strong,nonatomic,readonly,class,nullable) NSData *appleRootCACertificateData;
@property(strong,nonatomic,readonly,class,nullable) NSData *deviceIdentifierData;

#pragma mark - Receipt data
@property(strong,readonly) NSData *receiptData;

#pragma mark - Parsed receipt
@property(nullable,strong,readonly) NSDate *creationDate; //!< Date the receipt was created.
@property(nullable,strong,readonly) NSDate *expirationDate; //!< Date the receipt expires.

@property(nullable,strong,readonly) NSString *appBundleIdentifier; //!< The app's bundle ID.  Corresponds to value of Info.plist CFBundleIdentifier.
@property(nullable,strong,readonly) NSString *appVersion; //!< The app's version number. Corresponds to value of Info.plist CFBundleVersion (iOS).
@property(nullable,strong,readonly) NSString *originalAppVersion; //!< The version of the app that was originally purchase. Corresponds to value of Info.plist CFBundleVersion (iOS).

@property(nullable,strong,readonly) NSArray<OCLicenseAppStoreReceiptInAppPurchase *> *inAppPurchases;


@property(nullable,readonly,strong,class) OCLicenseAppStoreReceipt *defaultReceipt;

- (instancetype)initWithReceiptData:(NSData *)receiptData;

- (OCLicenseAppStoreReceiptParseError)parse;

@end

NS_ASSUME_NONNULL_END

#import "OCLicenseAppStoreReceiptInAppPurchase.h"
