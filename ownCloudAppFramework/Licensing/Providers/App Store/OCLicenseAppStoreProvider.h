//
//  OCLicenseAppStoreProvider.h
//  ownCloud
//
//  Created by Felix Schwarz on 24.11.19.
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

#import <ownCloudSDK/ownCloudSDK.h>

#import "OCLicenseProvider.h"
#import "OCLicenseAppStoreItem.h"
#import "OCLicenseAppStoreReceipt.h"
#import "OCLicenseManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OCLicenseAppStoreRestorePurchasesCompletionHandler)(NSError * _Nullable error);
typedef void(^OCLicenseAppStoreRefreshProductsCompletionHandler)(NSError * _Nullable error);

typedef NS_ENUM(NSInteger, OCLicenseAppStoreProviderError)
{
	OCLicenseAppStoreProviderErrorPurchasesNotAllowed,
	OCLicenseAppStoreProviderErrorPurchasesNotAllowedForVPPCopies
};

@interface OCLicenseAppStoreProvider : OCLicenseProvider <OCLogTagging>
{
	OCLicenseAppStoreReceipt *_receipt;
}

@property(nullable,strong,readonly,nonatomic) OCLicenseAppStoreReceipt *receipt;

@property(strong) NSArray<OCLicenseAppStoreItem *> *items;

@property(nonatomic,readonly) BOOL purchasesAllowed;
@property(nonatomic,readonly) BOOL isVolumePurchase;

#pragma mark - Init
- (instancetype)initWithItems:(NSArray<OCLicenseAppStoreItem *> *)items;

#pragma mark - Refreshing products
- (void)refreshProductsWithCompletionHandler:(OCLicenseAppStoreRefreshProductsCompletionHandler)completionHandler; //!< Re-requests the list of products from the App Store
- (void)refreshProductsIfNeededWithCompletionHandler:(OCLicenseAppStoreRefreshProductsCompletionHandler)completionHandler; //!< Requests the list of products from the App Store if it hasn't already (or failed due to f.ex. a lack of connectivity)

#pragma mark - Restoring IAPs
- (void)restorePurchasesWithCompletionHandler:(OCLicenseAppStoreRestorePurchasesCompletionHandler)completionHandler; //!< Restores in-app purchases and calls the completion handler when done

@end

@interface OCLicenseManager (AppStore)

@property(readonly,nonatomic,strong,nullable,class) OCLicenseAppStoreProvider *appStoreProvider; //! Convenience accessor for the AppStore Provider 

@end

extern OCLicenseProviderIdentifier OCLicenseProviderIdentifierAppStore;

extern NSErrorDomain OCLicenseAppStoreProviderErrorDomain;

NS_ASSUME_NONNULL_END

