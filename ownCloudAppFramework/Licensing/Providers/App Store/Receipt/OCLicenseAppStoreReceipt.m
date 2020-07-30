//
//  OCLicenseAppStoreReceipt.m
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

#import <UIKit/UIKit.h>

#import <openssl/err.h>
#import <openssl/x509.h>
#import <openssl/pkcs7.h>
#import <openssl/objects.h>
#import <openssl/sha.h>

#import "OCLicenseAppStoreReceipt.h"
#import "OCLicenseAppStoreReceiptInAppPurchase.h"
#import "OCASN1.h"

#pragma mark - Receipt parser
@implementation OCLicenseAppStoreReceipt

+ (NSData *)appleRootCACertificateData
{
	NSURL *url;

	if ((url = [[NSBundle bundleForClass:[self class]] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"]) != nil)
	{
		return ([[NSData alloc] initWithContentsOfURL:url]);
	}

	return (nil);
}

+ (NSData *)deviceIdentifierData
{
	NSUUID *deviceUUID;
	NSData *deviceUUIDData = nil;

	if ((deviceUUID = [[UIDevice currentDevice] identifierForVendor]) != nil)
	{
		uuid_t uuid;

		[deviceUUID getUUIDBytes:(uint8_t *)&uuid];

		deviceUUIDData = [NSData dataWithBytes:(void *)&uuid length:sizeof(uuid)];
	}

	return (deviceUUIDData);
}

+ (OCLicenseAppStoreReceipt *)defaultReceipt
{
	if (NSBundle.mainBundle.appStoreReceiptURL != nil)
	{
		NSData *receiptData;

		if ((receiptData = [NSData dataWithContentsOfURL:NSBundle.mainBundle.appStoreReceiptURL]) != nil)
		{
			return ([[self alloc] initWithReceiptData:receiptData]);
		}
	}

	return (nil);
}

- (instancetype)initWithReceiptData:(NSData *)receiptData
{
	if ((self = [super init]) != nil)
	{
		_receiptData = receiptData;
	}

	return (self);
}

- (OCLicenseAppStoreReceiptParseError)parse
{
	NSData *receiptData, *rootCAData;
	OCLicenseAppStoreReceiptParseError error = OCLicenseAppStoreReceiptParseErrorNone;

	// Fetch essentials
	if ((receiptData = _receiptData) == nil)
	{
		return(OCLicenseAppStoreReceiptParseErrorNoReceipt);
	}

	if ((rootCAData = [OCLicenseAppStoreReceipt appleRootCACertificateData]) == nil)
	{
		return(OCLicenseAppStoreReceiptParseErrorNoRootCA);
	}

	if ([OCLicenseAppStoreReceipt deviceIdentifierData] == nil)
	{
		return(OCLicenseAppStoreReceiptParseErrorNoDeviceID);
	}

	// OpenSSL setup
	ERR_load_X509_strings();
	ERR_load_PKCS7_strings();
	OpenSSL_add_all_digests();

	// Parse receipt
	const uint8_t *p_receiptData = receiptData.bytes, *p_caData = rootCAData.bytes;

	PKCS7 *pkcs7 = NULL;
	X509 *x509 = NULL;
	X509_STORE *x509Store = NULL;
	BIO *receiptContents = NULL;

	do
	{
		// Receipt -> PKCS7
		error = OCLicenseAppStoreReceiptParseErrorPKCS7Decode;
		if ((pkcs7 = d2i_PKCS7(NULL, &p_receiptData, receiptData.length)) == NULL) { break; }

		error = OCLicenseAppStoreReceiptParseErrorPKCS7Unsigned;
		if (!PKCS7_type_is_signed(pkcs7)) { break; }

		error = OCLicenseAppStoreReceiptParseErrorPKCS7ContentsNotData;
		if (!PKCS7_type_is_data(pkcs7->d.sign->contents)) { break; }

		// Root Cert -> X509
		error = OCLicenseAppStoreReceiptParseErrorX509Store;
		if ((x509Store = X509_STORE_new()) == NULL) { break; }

		error = OCLicenseAppStoreReceiptParseErrorX509Certificate;
		if ((x509 = d2i_X509(NULL, &p_caData, rootCAData.length)) == NULL) { break; }

		X509_STORE_add_cert(x509Store, x509);

		// Verify signature
		error = OCLicenseAppStoreReceiptParseErrorSignatureVerification;
		if ((receiptContents = BIO_new(BIO_s_mem())) == NULL) { break; }

		if (PKCS7_verify(pkcs7, NULL, x509Store, NULL, receiptContents, 0) != 1) { break; }
		if (ERR_get_error() != 0) { break; }

		// Parse ASN.1 contents
		ASN1_OCTET_STRING *asn1;

		if ((asn1 = pkcs7->d.sign->contents->d.data) != NULL)
		{
			[[[OCASN1 alloc] initWithData:asn1->data length:asn1->length] parseSetsOfSequencesWithContainerProvider:nil interpreter:^OCLicenseAppStoreReceiptParseError(id container, OCLicenseAppStoreReceiptFieldType fieldType, OCASN1 *contents) {
				OCLicenseAppStoreReceiptParseError error = OCLicenseAppStoreReceiptParseErrorNone;

				switch (fieldType)
				{
					case OCLicenseAppStoreReceiptFieldTypeAppBundleIdentifier:
						self->_appBundleIdentifier = contents.UTF8String;
					break;

					case OCLicenseAppStoreReceiptFieldTypeAppVersion:
						self->_appVersion = contents.UTF8String;
					break;

					case OCLicenseAppStoreReceiptFieldTypeAppOriginalVersion:
						self->_originalAppVersion = contents.UTF8String;
					break;

					case OCLicenseAppStoreReceiptFieldTypeReceiptCreationDate:
						self->_creationDate = contents.RFC3339Date;
					break;

					case OCLicenseAppStoreReceiptFieldTypeReceiptExpirationDate:
						self->_expirationDate = contents.RFC3339Date;
					break;

					case OCLicenseAppStoreReceiptFieldTypeInAppPurchase:
						error = [contents parseSetsOfSequencesWithContainerProvider:^id{
							return ([OCLicenseAppStoreReceiptInAppPurchase new]);
						} interpreter:^OCLicenseAppStoreReceiptParseError(OCLicenseAppStoreReceiptInAppPurchase *iap, OCLicenseAppStoreReceiptFieldType fieldType, OCASN1 *contents) {

							return ([iap parseField:fieldType withContents:contents]);
						}];

						self->_inAppPurchases = (self->_inAppPurchases != nil) ? [self->_inAppPurchases arrayByAddingObjectsFromArray:contents.containers] : contents.containers;
					break;

					default:
					break;
				}

				return (error);
			}];
		}

		// DONE!
		error = OCLicenseAppStoreReceiptParseErrorNone;
	}while(NO);


	// Free resources
	if (receiptContents!=NULL)
	{
		BIO_free(receiptContents);
		receiptContents = NULL;
	}

	if (x509!=NULL)
	{
		X509_free(x509);
		x509 = NULL;
	}

	if (x509Store!=NULL)
	{
		X509_STORE_free(x509Store);
		x509Store = NULL;
	}

	if (pkcs7!=NULL)
	{
		PKCS7_free(pkcs7);
		pkcs7 = NULL;
	}

	EVP_cleanup(); // "Remove all ciphers and digests from the table"

	return (error);
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"<%@: %p, receiptData: %@, creationDate: %@, expirationDate: %@, appBundleIdentifier: %@, appVersion: %@, originalAppVersion: %@, inAppPurchases: %@>", NSStringFromClass(self.class), self, _receiptData, _creationDate, _expirationDate, _appBundleIdentifier, _appVersion, _originalAppVersion, _inAppPurchases]);
}

@end
