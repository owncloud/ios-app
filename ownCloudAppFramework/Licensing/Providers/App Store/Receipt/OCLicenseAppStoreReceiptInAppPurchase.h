//
//  OCLicenseAppStoreReceiptInAppPurchase.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 03.12.19.
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
#import "OCLicenseAppStoreReceipt.h"

@class OCASN1;

NS_ASSUME_NONNULL_BEGIN

@interface OCLicenseAppStoreReceiptInAppPurchase : NSObject

@property(nullable,readonly,strong) NSNumber *quantity;
@property(nullable,readonly,strong) OCLicenseAppStoreProductIdentifier productID;

@property(nullable,readonly,strong) NSDate *purchaseDate;
@property(nullable,readonly,strong) NSDate *originalPurchaseDate;

@property(nullable,readonly,strong) NSDate *cancellationDate;

@property(nullable,readonly,strong) NSDate *subscriptionExpirationDate;
@property(nullable,readonly,strong) NSNumber *subscriptionInIntroOfferPeriod;

@property(nullable,readonly,strong) OCLicenseAppStoreLineItemID webOrderLineItemID;

@property(nullable,readonly,strong) OCLicenseAppStoreTransactionID transactionID;
@property(nullable,readonly,strong) OCLicenseAppStoreTransactionID originalTransactionID;

- (OCLicenseAppStoreReceiptParseError)parseField:(OCLicenseAppStoreReceiptFieldType)fieldType withContents:(OCASN1 *)contents;

@end

NS_ASSUME_NONNULL_END
