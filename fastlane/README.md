fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios beta
```
fastlane ios beta
```
Push a new beta build to TestFlight
### ios register_new_devices
```
fastlane ios register_new_devices
```
Register new devices to Apple portal
### ios build_ipa_ad_hoc
```
fastlane ios build_ipa_ad_hoc
```
Ad-Hoc Distribution IPA generation
### ios screenshots
```
fastlane ios screenshots
```
Generate the screenshots for the AppStore
### ios badgeIcon
```
fastlane ios badgeIcon
```
BadgeIcon
### ios build_ipa_enterprise_in_house
```
fastlane ios build_ipa_enterprise_in_house
```
In-House Enterprise IPA generation

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
