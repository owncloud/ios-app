# App Build Flags

## Description

App Build Flags can be used to control the inclusion or exclusion of certain functionality or features.

## Usage in Branding

A space-separated list of flags can be specified in the `Branding.plist` with the key `app.build-flags`, f.ex.:

```xml
<key>app.build-flags</key>
<string>DISABLE_BACKGROUND_LOCATION</string>
```

## Flags

The following options can be used as `APP_BUILD_FLAGS`:

### `DISABLE_BACKGROUND_LOCATION`

Removes the following from the app:
- the option for location-triggered background uploads from Settings
- the location description keys from the app's `Info.plist`

Not used by default.
