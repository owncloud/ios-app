#  Licensing

## Overview

The `OCLicense` set of classes allow gating and granting access to features through an extensible number of different mechanisms through a single, unified interface:

- `OCLicenseFeature` represents a particular feature for which access is gated.

- `OCLicenseProduct` represents a product and is defined by a collection of features.
	- for an IAP unlocking a *single feature*, that product would be defined by that single feature
	- for an *Unlock all* IAP, that product would be defined by *all* features
	- this allows creating tailored *products* consisting of a particular feature set, representing actual products

- `OCLicenseEntitlement` represents the entitlement to use a product. An entitlement
	- includes an `expiryDate` property (to allow trials + subscription expirations)
	- identifies origin of the entitlement

- `OCLicenseOffer` represents an offer to purchase a product

- `OCLicenseProvider` retrieve and provide information 
	- about licensed/purchased products in the form of `OCLicenseEntitlement`s, sourced from f.ex.
		- In App Purchases
		- Subscriptions
		- License Information pulled from a server
		- App Store Receipt original purchase date
	- about offers in the form of `OCLicenseOffer`, source from f.ex.
		- StoreKit (App Store)

- `OCLicenseManager` puts all the pieces together and provides APIs to determine the current status and subscription to changes
