fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios register_new_devices

```sh
[bundle exec] fastlane ios register_new_devices
```

Register new devices to Apple portal

### ios build_ipa_ad_hoc

```sh
[bundle exec] fastlane ios build_ipa_ad_hoc
```

Ad-Hoc Distribution IPA generation

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate the screenshots for the AppStore

### ios prepare_metadata

```sh
[bundle exec] fastlane ios prepare_metadata
```

Create Metadata Release Notes, Screenshots and push to git

### ios release_on_appstore

```sh
[bundle exec] fastlane ios release_on_appstore
```

Create Release Notes, Screenshots, Build, Upload of regular iOS App and EMM App

### ios owncloud_regular_build

```sh
[bundle exec] fastlane ios owncloud_regular_build
```



### ios owncloud_kiteworks_build

```sh
[bundle exec] fastlane ios owncloud_kiteworks_build
```



### ios owncloud_emm_build

```sh
[bundle exec] fastlane ios owncloud_emm_build
```



### ios owncloud_online_build

```sh
[bundle exec] fastlane ios owncloud_online_build
```



### ios owncloud_branding_adhoc_build

```sh
[bundle exec] fastlane ios owncloud_branding_adhoc_build
```



### ios owncloud_branding_appstore_build

```sh
[bundle exec] fastlane ios owncloud_branding_appstore_build
```



### ios owncloud_ownbrander_build

```sh
[bundle exec] fastlane ios owncloud_ownbrander_build
```



### ios owncloud_enterprise_build

```sh
[bundle exec] fastlane ios owncloud_enterprise_build
```



### ios generate_appicon

```sh
[bundle exec] fastlane ios generate_appicon
```



### ios build_ipa_in_house

```sh
[bundle exec] fastlane ios build_ipa_in_house
```

In-House Enterprise IPA generation

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
