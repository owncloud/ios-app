//
//  OCLicenseTransaction.h
//  ownCloudApp
//
//  Created by Felix Schwarz on 05.12.19.
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
#import "OCLicenseTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class OCLicenseProvider;
@class OCLicenseProduct;

typedef NSString* OCLicenseTransactionIdentifier;

@interface OCLicenseTransaction : NSObject

@property(nullable,weak) OCLicenseProvider *provider;

@property(nullable,strong) OCLicenseTransactionIdentifier identifier; //!< Transaction ID

@property(assign) OCLicenseType type; //!< Type

@property(assign) NSInteger quantity; //!< Quantity
@property(nullable,strong) NSString *name; //!< Name of item (typically product name)

@property(nullable,strong) OCLicenseProductIdentifier productIdentifier;
@property(nullable,strong,nonatomic,readonly) OCLicenseProduct *product;

@property(nullable,strong) NSDate *date;
@property(nullable,strong) NSDate *endDate;
@property(nullable,strong) NSDate *cancellationDate;

@property(nullable,strong,nonatomic) NSArray<NSDictionary<NSString *, id> *> *tableRows;
@property(nullable,strong,nonatomic) NSArray<NSDictionary<NSString *, NSString *> *> *displayTableRows;

@property(nullable,strong) NSDictionary<NSString *, NSURL *> *links;

+ (instancetype)transactionWithProvider:(nullable OCLicenseProvider *)provider identifier:(OCLicenseTransactionIdentifier)identifier type:(OCLicenseType)type quantity:(NSInteger)quantity name:(NSString *)name productIdentifier:(nullable OCLicenseProductIdentifier)productIdentifier date:(nullable NSDate *)date endDate:(nullable NSDate *)endDate cancellationDate:(nullable NSDate *)cancellationDate;

+ (instancetype)transactionWithProvider:(nullable OCLicenseProvider *)provider tableRows:(NSArray<NSDictionary<NSString *, id> *> *)tableRows;

@end

NS_ASSUME_NONNULL_END
