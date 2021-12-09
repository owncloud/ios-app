//
//  OCLicenseAppStoreReceiptInAppPurchase.m
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

#import "OCLicenseAppStoreReceiptInAppPurchase.h"
#import "OCASN1.h"

@implementation OCLicenseAppStoreReceiptInAppPurchase

- (OCLicenseAppStoreReceiptParseError)parseField:(OCLicenseAppStoreReceiptFieldType)fieldType withContents:(OCASN1 *)contents
{
	switch (fieldType)
	{
		case OCLicenseAppStoreReceiptFieldTypeIAPQuantity:
			_quantity = contents.integer;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPProductID:
			_productID = contents.UTF8String;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPPurchaseDate:
			_purchaseDate = contents.RFC3339Date;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPOriginalPurchaseDate:
			_originalPurchaseDate = contents.RFC3339Date;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPSubscriptionExpirationDate:
			_subscriptionExpirationDate = contents.RFC3339Date;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPTransactionID:
			self->_transactionID = contents.UTF8String;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPOriginalTransactionID:
			self->_originalTransactionID = contents.UTF8String;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPCancellationDate:
			self->_cancellationDate = contents.RFC3339Date;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPWebOrderLineItemID:
			self->_webOrderLineItemID = contents.integer;
		break;

		case OCLicenseAppStoreReceiptFieldTypeIAPSubscriptionInIntroOfferPeriod:
			self->_subscriptionInIntroOfferPeriod = contents.integer;
		break;

		default:
		break;
	}

	return (OCLicenseAppStoreReceiptParseErrorNone);
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"<%@: %p, quantity: %@, productID: %@, purchaseDate: %@, originalPurchaseDate: %@, cancellationDate: %@, subscriptionExpirationDate: %@, subscriptionInIntroOfferPeriod: %@, webOrderLineItemID: %@, transactionID: %@, originalTransactionID: %@>", NSStringFromClass(self.class), self, _quantity, _productID, _purchaseDate, _originalPurchaseDate, _cancellationDate, _subscriptionExpirationDate, _subscriptionInIntroOfferPeriod, _webOrderLineItemID, _transactionID, _originalTransactionID]);
}

@end
