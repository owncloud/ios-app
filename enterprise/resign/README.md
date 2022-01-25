# Script to resign your iOS ownCloud App

This script allows you to resign the ownCloud App IPA file with a different Apple certificate.

## App IDs and Provisioning Files

1. You need to generate the following App IDs with `App Groups` and `Associated Domains` enabled on the Apple Developer Portal `Identifiers` section:

   - `com.yourcompany.ios-app`

   - `com.yourcompany.ios-app.ownCloud-File-Provider`

   - `com.yourcompany.ios-app.ownCloud-File-ProviderUI`

   - `com.yourcompany.ios-app.ownCloud-Intent`

   - `com.yourcompany.ios-app.ownCloud-Share-Extension`

2. Generate one App Group:

   - `group.com.yourcompany.ios-app`



     Please keep the prefix `group.` and append the bundle identifier of the app target.

3. Edit the App IDs and assign the App Group created on step 2.

4. Generate the mobile provisioning profiles (App Store, In House or Ad-Hoc) for all 4 App IDs using a Distribution certificate (this certificate must be installed on the computer and its common name will be used as parameter on the script)

## Certificate

- Get the name of your signing certificate. In most cases this will be named `iPhone Distribution: YOUR COMPANY`.

## Associated Domains

Create a text file containing a list of line-break separated domain names (FQN) and name it `domains.txt`. This file is expected to be found in the same folder where this `README.md` file is stored. Currently only domains of type `applinks` are supported (others being `webcredentials` and `appclips`).

## Instructions

1. Rename your `.ipa` file to `unsigned.ipa`

2. Put the `unsigned.ipa` on the folder `App/`

3. Put your mobile provisioning inside `Provisioning Files/`

4. The mobile provisioning must be named:

   - `App.mobileprovision`
   - `FileProvider.mobileprovision`
   - `FileProviderUI.mobileprovision`
   - `Intent.mobileprovision`
   - `ShareExtension.mobileprovision`

5. Execute the script

   - `sh resignOwncloudApp "COMMON NAME DISTRIBUTION CERT"`

   - `sh resignOwncloudApp "COMMON NAME DISTRIBUTION CERT"`



     Replace `"COMMON NAME DISTRIBUTION CERT"` with the name of your certificate, e.g. `"iPhone Distribution: YOUR COMPANY"`.



## IPA Resigned Entitlements Inspection

To check the resigning entitlements of a signed IPA file, please use the script

`./resignInspector.sh "Path to signed.ipa"`

to output the entitlements of the IPA file and all targets.
