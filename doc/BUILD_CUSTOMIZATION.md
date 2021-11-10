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

### `DISABLE_APPSTORE_LICENSING`

Removes the following from the app:
- App Store integration for OCLicense
- App Store related view controllers and settings section


# Custom Schemes

## Description

The app uses two URL schemes:
- `oc` for authentication
- `owncloud` for private links

Both schemes are part of the app's `Info.plist`, which can only be changed at build time.

## Usage in Branding

### Private Links

The default `owncloud` app URL scheme in `Info.plist` can be changed by providing an alternative scheme name in the `Branding.plist` with the key `app.custom-app-scheme`, f.ex.:

```xml
<key>app.custom-app-scheme</key>
<string>myscheme</string>
```

### Authentication

The default `oc` app URL scheme in `Info.plist` can be changed by providing an alternative scheme name in the `Branding.plist` with the key `app.custom-auth-scheme`, f.ex.:

```xml
<key>app.custom-auth-scheme</key>
<string>ms</string>
```

The change in the `Info.plist` is only necessary when an external browser is used for authentication via OAuth2 or OIDC. In that case, the scheme must also be changed in the regular options for OIDC and OAuth2 authentication methods:

```xml
<key>authentication-oauth2.oa2-redirect-uri</key>
<string>ms://ios.owncloud.com</string>
<key>authentication-oauth2.oidc-redirect-uri</key>
<string>ms://ios.owncloud.com</string>
```

Depending on OAuth2 and OIDC implementation on the server side:
- it may be necessary to also adapt the registered redirect URI on the server
- authentication could fail if not adapted on the server
