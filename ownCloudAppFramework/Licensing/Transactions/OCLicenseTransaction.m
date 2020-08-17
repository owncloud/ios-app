//
//  OCLicenseTransaction.m
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

#import "OCLicenseTransaction.h"
#import "OCLicenseManager.h"
#import "OCLicenseProvider.h"
#import "OCLicenseProduct.h"

@implementation OCLicenseTransaction

+ (instancetype)transactionWithProvider:(nullable OCLicenseProvider *)provider identifier:(OCLicenseTransactionIdentifier)identifier type:(OCLicenseType)type quantity:(NSInteger)quantity name:(NSString *)name productIdentifier:(nullable OCLicenseProductIdentifier)productIdentifier date:(nullable NSDate *)date endDate:(nullable NSDate *)endDate cancellationDate:(nullable NSDate *)cancellationDate
{
	OCLicenseTransaction *transaction = [OCLicenseTransaction new];

	transaction.provider = provider;

	transaction.identifier = identifier;
	transaction.type = type;

	transaction.quantity = quantity;
	transaction.name = name;

	transaction.productIdentifier = productIdentifier;
	transaction.date = date;
	transaction.endDate = endDate;
	transaction.cancellationDate = cancellationDate;

	return (transaction);
}

+ (instancetype)transactionWithProvider:(nullable OCLicenseProvider *)provider tableRows:(NSArray<NSDictionary<NSString *, id> *> *)tableRows
{
	OCLicenseTransaction *transaction = [OCLicenseTransaction new];

	transaction.provider = provider;
	transaction.tableRows = tableRows;

	return (transaction);
}

+ (NSDateFormatter *)localizedDateFormatter
{
	static NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];

		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
		dateFormatter.timeStyle = NSDateFormatterMediumStyle;
		dateFormatter.locale = NSLocale.currentLocale;
	});

	return (dateFormatter);
}

- (OCLicenseProduct *)product
{
	return ([self.provider.manager productWithIdentifier:self.productIdentifier]);
}

- (NSArray<NSDictionary<NSString *,id> *> *)tableRows
{
	if (_tableRows == nil)
	{
		NSMutableArray<NSDictionary<NSString *,id> *> *tableRows = [@[
			@{ OCLocalized(@"Type") 	: [OCLicenseProduct stringForType:self.type] 	},
			@{ OCLocalized(@"Quantity") : @(self.quantity) 				}
		] mutableCopy];

		if (_name != nil)
		{
			[tableRows insertObject:@{
				OCLocalized(@"Product")	: _name
			} atIndex:0];
		}

		if (_date != nil)
		{
			[tableRows addObject:@{
				OCLocalized(@"Date")	 : _date
			}];
		}

		if (_cancellationDate != nil)
		{
			[tableRows addObject:@{
				OCLocalized(@"Cancelled"): _cancellationDate
			}];
		}

		if (_endDate != nil)
		{
			[tableRows addObject:@{
				OCLocalized(@"Ends")	: _endDate
			}];
		}

		_tableRows = tableRows;
	}

	return (_tableRows);
}

- (NSArray<NSDictionary<NSString *,NSString *> *> *)displayTableRows
{
	if (_displayTableRows == nil)
	{
		NSArray<NSDictionary<NSString *,id> *> *tableRows = nil;

		if (((tableRows = self.tableRows) != nil) && (tableRows.count > 0))
		{
			NSMutableArray<NSDictionary<NSString *, NSString *> *> *displayTableRows = [NSMutableArray new];

			for (NSDictionary<NSString *,id> *tableRow in tableRows)
			{
				NSMutableDictionary<NSString *, NSString *> *row = [NSMutableDictionary new];

				[tableRow enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
					if ([obj isKindOfClass:NSNumber.class])
					{
						obj = ((NSNumber *)obj).stringValue;
					}

					if ([obj isKindOfClass:NSDate.class])
					{
						obj = [[OCLicenseTransaction localizedDateFormatter] stringFromDate:obj];
					}

					if (![obj isKindOfClass:NSString.class])
					{
						obj = ((NSObject *)obj).description;
					}

					row[OCLocalized(key)] = obj;
				}];

				[displayTableRows addObject:row];
			}

			_displayTableRows = displayTableRows;
		}
	}

	return (_displayTableRows);
}

- (NSString *)description
{
	return ([NSString stringWithFormat:@"<%@: %p, %@>", NSStringFromClass(self.class), self, self.displayTableRows]);
}

@end
