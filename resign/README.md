#Script to resign your iOS ownCloud App

This script allows you to resign the ownCloud App IPA file with a different Apple certificate.

##Certificates

1. We need to generate on the Apple Developer Portal the following App IDs with App Group Enable Services:
	- com.yourcompany.ios-app
	- com.yourcompany.ios-app.ownCloud-File-Provider
	- com.yourcompany.ios-app.ownCloud-Intent
2. Generate one App Group:
	- group.com.yourcompany.ios-app
3. Edit the App IDs and assign the App Group created on step 2.
4. Generate the mobile provisioning (App Store or Ad-Hoc) for both App IDs using a Distribution certificate (this certificate must be installed on the computer and its common name will be used as parameter on the script)


##Instructions

1. Rename your `.ipa` file to `unsigned.ipa`
2. Put the `unsigned.ipa` on the folder `App/ad-hoc/` or `App/app-store/`
3. Put your mobile provisioning inside `Provisioning Files/ad-hoc/` or `Provisioning Files/app-store/`
4. The mobile provisioning must be named:
	- App.mobileprovision
	- FileProvider.mobileprovision
	- Intent.mobileprovision
5. Execute the script
	- sh resignOwncloudApp "COMMON NAME DISTRIBUTION CERT" "ad-hoc"
	- sh resignOwncloudApp "COMMON NAME DISTRIBUTION CERT" "app-store"
