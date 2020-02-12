//
//  OCASN1.m
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

#import "OCASN1.h"
#import "NSDate+RFC3339.h"

#import <Security/Security.h>

#import <openssl/err.h>
#import <openssl/x509.h>
#import <openssl/pkcs7.h>
#import <openssl/objects.h>
#import <openssl/sha.h>

@implementation OCASN1

- (instancetype)initWithData:(void *)data length:(size_t)length
{
	if ((self = [super init]) != nil)
	{
		_data = data;
		_length = length;
	}

	return (self);
}

- (NSDate *)RFC3339Date
{
	NSString *rfcDateString;

	if ((rfcDateString = self.IA5String) != nil)
	{
		return ([NSDate dateFromRFC3339DateString:rfcDateString]);
	}

	return (nil);
}

- (NSString *)_stringWithTag:(int)tag encoding:(NSStringEncoding)encoding
{
	int contentClass=0, contentTag=0;
	long contentLength=0;
	const unsigned char *p_content = NULL;

	contentTag = 0;
	contentLength = 0;
	p_content = _data;

	ASN1_get_object(&p_content, &contentLength, &contentTag, &contentClass, _length);
	if (contentTag!=tag) { return(nil); }

	return ([[NSString alloc] initWithBytes:(const void *)p_content length:contentLength encoding:encoding]);
}

- (NSString *)UTF8String
{
	return ([self _stringWithTag:V_ASN1_UTF8STRING encoding:NSUTF8StringEncoding]);
}

- (NSString *)IA5String
{
	return ([self _stringWithTag:V_ASN1_IA5STRING encoding:NSASCIIStringEncoding]);
}

- (NSNumber *)integer
{
	int contentClass=0, contentTag=0;
	long contentLength=0;
	const unsigned char *p_content = NULL;

	contentTag = 0;
	contentLength = 0;
	p_content = _data;

	ASN1_get_object(&p_content, &contentLength, &contentTag, &contentClass, _length);
	if (contentTag == V_ASN1_INTEGER)
	{
		NSUInteger number = 0;

		for (NSUInteger offset=0; offset < contentLength; offset++)
		{
			number = (number << 8L) | p_content[offset];
		}

		return (@(number));
	}

	return (nil);
}

- (OCLicenseAppStoreReceiptParseError)parseSetsOfSequencesWithContainerProvider:(nullable id(^)(void))containerProvider interpreter:(OCLicenseAppStoreReceiptParseError(^)(id container, OCLicenseAppStoreReceiptFieldType, OCASN1 *contents))interpreter
{
	OCLicenseAppStoreReceiptParseError error = OCLicenseAppStoreReceiptParseErrorNone;

	const unsigned char *p_octetData = _data;
	const unsigned char *p_octetEndByte = p_octetData + _length;
	long objLength;
	int objTag, objClass;

	// Parse sets
	while(p_octetData < p_octetEndByte)
	{
		const unsigned char *p_setEnd;

		// Get set size
		ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_octetEndByte-p_octetData);
		if (objTag != V_ASN1_SET) { break; }

		p_setEnd = p_octetData + objLength;

		id parseResultContainer = (containerProvider != nil) ? containerProvider() : nil;

		// Parse set
		while (p_octetData < p_setEnd)
		{
			const unsigned char *p_seqEnd;
			int itemAttribType=0, itemAttribVersion=0;

			ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_setEnd-p_octetData);
			if (objTag != V_ASN1_SEQUENCE) { break; }

			p_seqEnd = p_octetData + objLength;

			// Parse seq
			// Get attribute type
			ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_seqEnd-p_octetData);
			if (objTag == V_ASN1_INTEGER)
			{
				if (objLength == 1)
				{
					#ifndef __clang_analyzer__
					itemAttribType = p_octetData[0];
					#endif
				}
				else
				{
					if (objLength == 2)
					{
						#ifndef __clang_analyzer__
						itemAttribType = (p_octetData[0] << 8)|p_octetData[1];
						#endif
					}
					else
					{
						break;
					}
				}
			}
			p_octetData += objLength;

			// Get attribute version
			ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_seqEnd-p_octetData);
			if ((objTag != V_ASN1_INTEGER) || (objLength!=1)) { break; }
			#ifndef __clang_analyzer__
			itemAttribVersion = p_octetData[0];
			#endif /* __clang_analyzer__ */
			p_octetData += objLength;

			// Get value
			ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_seqEnd-p_octetData);
			if (objTag == V_ASN1_OCTET_STRING)
			{
				// Interpret value
				OCLicenseAppStoreReceiptParseError interpreterError;

				if ((interpreterError = interpreter(parseResultContainer, itemAttribType, [[OCASN1 alloc] initWithData:(void *)p_octetData length:objLength])) != OCLicenseAppStoreReceiptParseErrorNone)
				{
					error = interpreterError;
					break;
				}
			}
			p_octetData += objLength;

			// Ignore all other objects until end of sequence
			while (p_octetData < p_seqEnd)
			{
				ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_seqEnd-p_octetData);
				p_octetData += objLength;
			};
		};

		// Ignore all other objects until end of set
		while (p_octetData < p_setEnd)
		{
			ASN1_get_object(&p_octetData, &objLength, &objTag, &objClass, p_setEnd-p_octetData);
			p_octetData += objLength;
		}

		if (parseResultContainer != nil)
		{
			if (_containers == nil)
			{
				_containers = [NSMutableArray new];
			}

			[_containers addObject:parseResultContainer];
		}
	};

	return (error);
}

@end
