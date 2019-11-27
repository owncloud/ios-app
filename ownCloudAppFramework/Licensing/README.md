#  Licensing

## Overview

The `OCLicense` set of classes allow gating and granting access to features through an extensible number of different mechanisms through a single, unified interface:

- `OCLicenseFeature` represents a particular feature for which access is gated.

- `OCLicenseProduct` represents a product and is defined by a collection of features.
	- for an IAP unlocking a *single feature*, that product would be defined by that single feature
	- for an *Unlock all* IAP, that product would be defined by *all* features
	- this allows creating tailored *products* consisting of a particular feature set, representing actual products

- `OCLicenseEnvironment` encapsulates information on an environment against which the authorization to use a product should be checked
	- typically defined by host name, TLS certificate, etc.

- `OCLicenseEntitlement` represents the entitlement to use a product. An entitlement
	- identifies its origin: where does it come from?
	- includes an `expiryDate` property (to allow trials + subscription expirations)
	- provides information on *validity* and *applicability*:
		- *validity*: if this entitlement should be considered at all (i.e. has not expired)
		- *applicability*: if this entitlement actually authorizes the use of a product in a certain `OCLicenseEnvironment`
			- can limit the authorization to use a product/feature to a certain domain/TLS certificate/public key

- `OCLicenseOffer` represents an offer to purchase a product

- `OCLicenseProvider` retrieve and provide information 
	- about licensed/purchased products in the form of `OCLicenseEntitlement`s, sourced from f.ex.
		- In App Purchases
		- Subscriptions
		- License Information pulled from a server
		- App Store Receipt original purchase date
	- about offers in the form of `OCLicenseOffer`, source from f.ex.
		- StoreKit (App Store)

- `OCLicenseManager` 
	- puts all these pieces together and provides APIs to determine if the usage of a certain feature is allowed
	- allows observation of single or groups of products and features in a particular environment and notify on change (handled through `OCLicenseObserver`)

## Hierarchy
- Sessions
	- `OCLicenseEnvironment`
- `OCLicenseManager` 
	
	- `OCLicenseFeature`s
	- `OCLicenseProduct`s
	- `OCLicenseProvider`s
		- `OCLicenseEntitlement`s
		- `OCLicenseOffer`s
	- `OCLicenseObserver`
		- app code

## Examples

#### Registering features and products
```objc
// Register features
[OCLicenseManger.sharedLicenseManager registerFeature:[OCLicenseFeature featureWithIdentifier:@"feature.document-scanning" localizedName:@"Document scanning"]];
[OCLicenseManger.sharedLicenseManager registerFeature:[OCLicenseFeature featureWithIdentifier:@"feature.push-notifications" localizedName:@"Push notification"]];

// Register products
[OCLicenseManger.sharedLicenseManager registerProduct:[OCLicenseProduct productWithIdentifier:@"product.document-scanner" localizedName:@"Document scanner" contents:@[
	@"feature.document-scanning"
]]];

[OCLicenseManger.sharedLicenseManager registerProduct:[OCLicenseProduct productWithIdentifier:@"product.document-scanner" localizedName:@"Push notifications" contents:@[
	@"feature.push-notifications"
]]];

[OCLicenseManger.sharedLicenseManager registerProduct:[OCLicenseProduct productWithIdentifier:@"product.unlock-all" localizedName:@"Unlock all" contents:@[
	@"com.owncloud.document-scanning",
	@"com.owncloud.push-notifications"
]]];
```

#### Determining state and reacting to changes
```objc
[OCLicenseManager.sharedLicenseManager observeProducts:nil features:@[ @"product.document-scanner" ] environment:core.environment withOwner:self updateHandler:^(OCLicenseObserver *observer, BOOL isInitial, OCLicenseAuthorizationStatus authorizationStatus){
	// Handle updates to authorization status to use the document scanner feature	
}];
```

## Setup

To comply with `StoreKit` requirements, the `OCLicense` system needs to be completely set up in the `-[UIApplicationDelegate application:didFinishLaunchingWithOptions:]` method. In particular, the `OCLicenseAppStoreProvider` method needs to be added to `OCLicenseManager` in that method.

## Reference
### App Store Receipt parsing
- RevenueCat: [Dissecting an App Store Receipt](https://www.revenuecat.com/2018/01/17/dissecting-an-app-store-receipt)
- Apple: [Validating Receipts Locally](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html)
- Apple: [Receipt Fields](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1)

### Non-consumable IAPs as trial mechanism
- MacRumors: [Free Trials for All Paid Apps Now Possible Thanks to Updated App Store Guidelines](https://www.macrumors.com/2018/06/05/app-store-app-free-trials-now-available/)
- Apple: [App Store Review Guidelines: In-App Purchases](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
