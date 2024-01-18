# Build Flags

## Description

Build Flags can be used to control the inclusion or exclusion of certain functionality or features at compile time.

## Usage in Branding

A **space-separated** list of flags can be specified in the `Branding.plist` with the key `build.flags`, f.ex.:

```xml
<key>build.flags</key>
<string>DISABLE_BACKGROUND_LOCATION</string>
```

## Flags

The following options can be used as `build.flags`:

### `DISABLE_BACKGROUND_LOCATION`

Removes the following from the app:
- the option for location-triggered background uploads from Settings
- the location description keys from the app's `Info.plist`

Not used by default.

### `DISABLE_APPSTORE_LICENSING`

Removes the following from the app:
- App Store integration for OCLicense
- App Store related view controllers and settings section

### `DISABLE_PLAIN_HTTP`

Removes the following from the app:
- the `NSAppTransportSecurity` dictionary from the app's `Info.plist`
- including the `NSAllowsArbitraryLoads` key that's needed to allow plain/unsecured HTTP connections
- 
### `REMOVE_EXTENSION_INTENTS`

Removes the Intents extension binary from the IPA after building the app with fastlane
