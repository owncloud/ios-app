//
//  OCASN1.h
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

NS_ASSUME_NONNULL_BEGIN

@interface OCASN1 : NSObject

@property(nullable,assign) void *data;
@property(assign) NSUInteger length;

@property(strong,nonatomic,readonly,nullable) NSString *UTF8String;
@property(strong,nonatomic,readonly,nullable) NSDate *RFC3339Date;
@property(strong,nonatomic,readonly,nullable) NSNumber *integer;

@property(strong,nullable) NSMutableArray *containers;

- (instancetype)initWithData:(void *)data length:(size_t)length;

- (OCLicenseAppStoreReceiptParseError)parseSetsOfSequencesWithContainerProvider:(nullable id(^)(void))containerProvider interpreter:(OCLicenseAppStoreReceiptParseError(^)(id container, OCLicenseAppStoreReceiptFieldType, OCASN1 *contents))interpreter;

@end

NS_ASSUME_NONNULL_END
