# Table of Contents

* [Changelog for 12.2.1](#changelog-for-owncloud-ios-client-1221-2024-04-30)
* [Changelog for 12.2.0](#changelog-for-owncloud-ios-client-1220-2024-04-23)
* [Changelog for 12.1.0](#changelog-for-owncloud-ios-client-1210-2024-01-29)
* [Changelog for 12.0.3](#changelog-for-owncloud-ios-client-1203-2023-08-31)
* [Changelog for 12.0.2](#changelog-for-owncloud-ios-client-1202-2023-06-23)
* [Changelog for 12.0.1](#changelog-for-owncloud-ios-client-1201-2023-06-15)
* [Changelog for 12.0.0](#changelog-for-owncloud-ios-client-1200-2023-06-12)
* [Changelog for 11.11.1](#changelog-for-owncloud-ios-client-11111-2022-10-30)
* [Changelog for 11.11.0](#changelog-for-owncloud-ios-client-11110-2022-09-26)
* [Changelog for 11.10.1](#changelog-for-owncloud-ios-client-11101-2022-08-02)
* [Changelog for 11.10.0](#changelog-for-owncloud-ios-client-11100-2022-05-18)
* [Changelog for 11.9.1](#changelog-for-owncloud-ios-client-1191-2022-03-29)
* [Changelog for 11.9.0](#changelog-for-owncloud-ios-client-1190-2022-03-16)
* [Changelog for 11.8.2](#changelog-for-owncloud-ios-client-1182-2022-01-17)
* [Changelog for 11.8.1](#changelog-for-owncloud-ios-client-1181-2021-12-22)
* [Changelog for 11.8.0](#changelog-for-owncloud-ios-client-1180-2021-12-01)
* [Changelog for 11.7.1](#changelog-for-owncloud-ios-client-1171-2021-09-22)
* [Changelog for 11.7.0](#changelog-for-owncloud-ios-client-1170-2021-07-29)
* [Changelog for 11.6.1](#changelog-for-owncloud-ios-client-1161-2021-06-24)
* [Changelog for 11.6.0](#changelog-for-owncloud-ios-client-1160-2021-05-12)
* [Changelog for 11.5.2](#changelog-for-owncloud-ios-client-1152-2021-03-03)
* [Changelog for 11.5.1](#changelog-for-owncloud-ios-client-1151-2021-02-17)
* [Changelog for 11.5.0](#changelog-for-owncloud-ios-client-1150-2021-02-10)
* [Changelog for 11.4.5 versions and below](#changelog-for-1145-versions-and-below)
# Changelog for ownCloud iOS Client [12.2.1] (2024-04-30)
The following sections list the changes in ownCloud iOS Client 12.2.1 relevant to
ownCloud admins and users.

[12.2.1]: https://github.com/owncloud/ios-app/compare/milestone/12.2.0...milestone/12.2.1

## Summary

* Bugfix - Detect attempts to bypass a lock timeout by changing the clock: [#1347](https://github.com/owncloud/ios-app/pull/1347)

## Details

* Bugfix - Detect attempts to bypass a lock timeout by changing the clock: [#1347](https://github.com/owncloud/ios-app/pull/1347)

   - detect attempts to bypass a lock timeout by changing the clock - code
   cleanups/modernizations of `AppLockManager` - supersedes #1324

   https://github.com/owncloud/ios-app/pull/1347

# Changelog for ownCloud iOS Client [12.2.0] (2024-04-23)
The following sections list the changes in ownCloud iOS Client 12.2.0 relevant to
ownCloud admins and users.

[12.2.0]: https://github.com/owncloud/ios-app/compare/milestone/12.1.0...milestone/12.2.0

## Summary

* Bugfix - Fix cleanup of Available Offline policies targeting unavailable spaces: [#1343](https://github.com/owncloud/ios-app/pull/1343)
* Change - Add required privacy manifests: [#1348](https://github.com/owncloud/ios-app/pull/1348)
* Enhancement - Improved sidebar with account-wide search: [#1320](https://github.com/owncloud/ios-app/pull/1320)
* Enhancement - Password Policy support: [#1325](https://github.com/owncloud/ios-app/pull/1325)

## Details

* Bugfix - Fix cleanup of Available Offline policies targeting unavailable spaces: [#1343](https://github.com/owncloud/ios-app/pull/1343)

   Fixes an issue arising from Available Offline policies targeting unavailable or
   detached spaces and removes the respective policies, preventing continued
   retries for files from inaccessible or removed spaces.

   https://github.com/owncloud/ios-app/pull/1343

* Change - Add required privacy manifests: [#1348](https://github.com/owncloud/ios-app/pull/1348)

   Adds the [privacy
   manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api?language=objc)
   [required by Apple starting May 1,
   2024](https://developer.apple.com/news/?id=3d8a9yyh) to the app and upgrades
   `krzyzanowskim/OpenSSL` to
   [3.1.5001](https://github.com/krzyzanowskim/OpenSSL/releases/tag/3.1.5001) to
   include a privacy manifest as [also required by
   Apple](https://developer.apple.com/support/third-party-SDK-requirements/).

   https://github.com/owncloud/ios-app/pull/1348

* Enhancement - Improved sidebar with account-wide search: [#1320](https://github.com/owncloud/ios-app/pull/1320)

   This PR: - removes `Quick Access` from the sidebar, redistributing its prior
   contents as follows: - `Recents`: promoted to a top-level sidebar item -
   `Favorites`: promoted to a top-level sidebar item - `Available Offline`:
   promoted to a top-level sidebar item - other Quick Access items: moved as
   suggestions to new top-level sidebar `Search` item, with a dedicated `Add to
   sidebar` button that allows re-adding the previous Quick Access items as saved
   search - Saved searches now appear as top-level items in the sidebar - adds
   custom user sidebar items - can be added via `Add to sidebar` - support drag and
   drop (also cross-account) - managed via context menu, swipe and `Remove from
   sidebar` actions - in the share extension automatically connects to the first
   account if only one account is in the account (superseding
   [#1296](https://github.com/owncloud/ios-app/pull/1296)) - incorporates the
   latest SDK with important fixes

   https://github.com/owncloud/ios-app/pull/1320

* Enhancement - Password Policy support: [#1325](https://github.com/owncloud/ios-app/pull/1325)

   This PR implements password policy support throughout the iOS client app,
   including: - an extensible password policy system based on rules, policies and
   validation reports with verbose error reporting for - characters and [character
   sets](https://developer.apple.com/documentation/foundation/nscharacterset) -
   lengths - byte counts - the generation of password policies based on server
   capabilities - a default password policy for servers that do not provide a
   password policy - a password generator based on password policy rules using
   "[cryptographically secure random
   bytes](https://developer.apple.com/documentation/security/1399291-secrandomcopybytes)"
   - a password composer for entering, editing and generating passwords with
   instant rule verification and feedback - one-tap password generation based on a
   server's password policy within Public Link creation - sharing of combined
   public link URL and password to the clipboard, Messages, Mail and more via the
   system share sheet directly after link generation, like f.ex.:

   ```
   Photos (https://demo.owncloud.org/s/D3WkWZOW8BUjeKr) | Password: 46CPou|#Pw5.
   ```

   https://github.com/owncloud/ios-app/issues/973
   https://github.com/owncloud/ios-app/pull/1325

# Changelog for ownCloud iOS Client [12.1.0] (2024-01-29)
The following sections list the changes in ownCloud iOS Client 12.1.0 relevant to
ownCloud admins and users.

[12.1.0]: https://github.com/owncloud/ios-app/compare/milestone/12.0.3...milestone/12.1.0

## Summary

* Bugfix - Available offline badge: [#1128](https://github.com/owncloud/ios-app/issues/1128)
* Bugfix - File Provider fixes: [#1294](https://github.com/owncloud/ios-app/pull/1294)
* Bugfix - Open ownCloud Links in App: [#1295](https://github.com/owncloud/ios-app/issues/1295)
* Bugfix - Show message in File Provider if no account has been set up: [#1306](https://github.com/owncloud/ios-app/pull/1306)
* Bugfix - Disable Markup Edit Mode iOS 17: [#1309](https://github.com/owncloud/ios-app/issues/1309)
* Bugfix - Adopt log format: [#11224](https://github.com/owncloud/client/issues/11224)
* Change - New account wizard: [#1274](https://github.com/owncloud/ios-app/pull/1274)
* Change - Text recognition actions for images: [#1283](https://github.com/owncloud/ios-app/pull/1283)
* Change - File extension / suffix protection: [#1292](https://github.com/owncloud/ios-app/issues/1292)
* Change - Share Action Extension "Save to ownCloud": [#1293](https://github.com/owncloud/ios-app/issues/1293)
* Change - Link naming: [#1297](https://github.com/owncloud/ios-app/issues/1297)
* Change - Remove Extension Build Flag (Intents): [#6112](https://github.com/owncloud/enterprise/issues/6112)

## Details

* Bugfix - Available offline badge: [#1128](https://github.com/owncloud/ios-app/issues/1128)

   Available offline badge was there after making unavailable offline.

   https://github.com/owncloud/ios-app/issues/1128

* Bugfix - File Provider fixes: [#1294](https://github.com/owncloud/ios-app/pull/1294)

   This branch addresses found issues in the File Provider: - fixes unanswered
   thumbnail requests (leading to infinite thumbnail responses) - fixes incorrect
   error being returned in response to thumbnail requests

   https://github.com/owncloud/ios-app/pull/1294

* Bugfix - Open ownCloud Links in App: [#1295](https://github.com/owncloud/ios-app/issues/1295)

   Fixed existing feature intending to open files/folders in app, by clicking a
   private link from outside.

   https://github.com/owncloud/ios-app/issues/1295

* Bugfix - Show message in File Provider if no account has been set up: [#1306](https://github.com/owncloud/ios-app/pull/1306)

   This PR makes the File Provider UI show a message if no account has been set up
   yet, offering to open the app. Previously, the FP UI was briefly shown and then
   dismissed.

   https://github.com/owncloud/ios-app/pull/1306

* Bugfix - Disable Markup Edit Mode iOS 17: [#1309](https://github.com/owncloud/ios-app/issues/1309)

   Fixed disabling edit mode in markup document view on iOS 17

   https://github.com/owncloud/ios-app/issues/1309

* Bugfix - Adopt log format: [#11224](https://github.com/owncloud/client/issues/11224)

   Use common http log format for ownCloud clients.

   https://github.com/owncloud/client/issues/11224

* Change - New account wizard: [#1274](https://github.com/owncloud/ios-app/pull/1274)

   - reimplementation of the new account wizard - support for reordering accounts
   in the sidebar via drag and drop - adds location breadcrumb dropdown in the
   viewer

   https://github.com/owncloud/ios-app/pull/1274

* Change - Text recognition actions for images: [#1283](https://github.com/owncloud/ios-app/pull/1283)

   Adds VisonKit interactions to the image viewer, allowing to select and interact
   with recognized content (f.ex. text) like in the Photos app.

   https://github.com/owncloud/ios-app/pull/1283

* Change - File extension / suffix protection: [#1292](https://github.com/owncloud/ios-app/issues/1292)

   Prevents users from removing or changing the suffix for new documents and
   document scanner.

   https://github.com/owncloud/ios-app/issues/1292

* Change - Share Action Extension "Save to ownCloud": [#1293](https://github.com/owncloud/ios-app/issues/1293)

   Adds a share action extension "Save to ownCloud", which will open the share
   sheet view.

   https://github.com/owncloud/ios-app/issues/1293

* Change - Link naming: [#1297](https://github.com/owncloud/ios-app/issues/1297)

   Adds a Name field for link shares, allowing to enter and edit the name of link
   shares.

   https://github.com/owncloud/ios-app/issues/1297

* Change - Remove Extension Build Flag (Intents): [#6112](https://github.com/owncloud/enterprise/issues/6112)

   Adds a build flag to remove app extensions from a IPA build.

   https://github.com/owncloud/enterprise/issues/6112

# Changelog for ownCloud iOS Client [12.0.3] (2023-08-31)
The following sections list the changes in ownCloud iOS Client 12.0.3 relevant to
ownCloud admins and users.

[12.0.3]: https://github.com/owncloud/ios-app/compare/milestone/12.0.2...milestone/12.0.3

## Summary

* Bugfix - Upload-Metadata: [#1227](https://github.com/owncloud/ios-app/issues/1227)
* Bugfix - Open Folder in Files.app: [#1240](https://github.com/owncloud/ios-app/issues/1240)
* Bugfix - Connection name: [#1254](https://github.com/owncloud/ios-app/issues/1254)
* Bugfix - Unable to access files from Files.app: [#1262](https://github.com/owncloud/ios-app/issues/1262)
* Bugfix - File Provider Crash: [#1266](https://github.com/owncloud/ios-app/issues/1266)
* Bugfix - Translation: [#1269](https://github.com/owncloud/ios-app/pull/1269)
* Bugfix - Open in Web for ownCloud 10: [#5747](https://github.com/owncloud/enterprise/issues/5747)
* Bugfix - Copy Item not working: [#5889](https://github.com/owncloud/enterprise/issues/5889)

## Details

* Bugfix - Upload-Metadata: [#1227](https://github.com/owncloud/ios-app/issues/1227)

   TUS -H Upload-Metadata: mtime missing

   https://github.com/owncloud/ios-app/issues/1227

* Bugfix - Open Folder in Files.app: [#1240](https://github.com/owncloud/ios-app/issues/1240)

   In some cases it was not possible to open Folder using iOS Files.app.

   https://github.com/owncloud/ios-app/issues/1240

* Bugfix - Connection name: [#1254](https://github.com/owncloud/ios-app/issues/1254)

   Connection name doesn't change immediately

   https://github.com/owncloud/ios-app/issues/1254

* Bugfix - Unable to access files from Files.app: [#1262](https://github.com/owncloud/ios-app/issues/1262)

   In some cases it was not possible to access files from the Files.app.

   https://github.com/owncloud/ios-app/issues/1262

* Bugfix - File Provider Crash: [#1266](https://github.com/owncloud/ios-app/issues/1266)

   IOS invokes a FileProvider method with a nil value, which causes a crash.

   https://github.com/owncloud/ios-app/issues/1266

* Bugfix - Translation: [#1269](https://github.com/owncloud/ios-app/pull/1269)

   Updated translations from Transifex.

   https://github.com/owncloud/ios-app/pull/1269

* Bugfix - Open in Web for ownCloud 10: [#5747](https://github.com/owncloud/enterprise/issues/5747)

   Open in Web feature was not available for ownCloud 10 instances in the app.

   https://github.com/owncloud/enterprise/issues/5747

* Bugfix - Copy Item not working: [#5889](https://github.com/owncloud/enterprise/issues/5889)

   Copy and paste to a Space was not working

   https://github.com/owncloud/enterprise/issues/5889

# Changelog for ownCloud iOS Client [12.0.2] (2023-06-23)
The following sections list the changes in ownCloud iOS Client 12.0.2 relevant to
ownCloud admins and users.

[12.0.2]: https://github.com/owncloud/ios-app/compare/milestone/12.0.1...milestone/12.0.2

## Summary

* Bugfix - Unable to authenticate using OpenID Connect: [#1219](https://github.com/owncloud/ios-app/issues/1219)
* Bugfix - Files.app: [#1223](https://github.com/owncloud/ios-app/pull/1223)
* Bugfix - Recent files view: [#1225](https://github.com/owncloud/ios-app/pull/1225)
* Bugfix - Attach files from third-party apps: [#1228](https://github.com/owncloud/ios-app/pull/1228)

## Details

* Bugfix - Unable to authenticate using OpenID Connect: [#1219](https://github.com/owncloud/ios-app/issues/1219)

   It was not able to authenticate using OpenID Connect

   https://github.com/owncloud/ios-app/issues/1219

* Bugfix - Files.app: [#1223](https://github.com/owncloud/ios-app/pull/1223)

   Solves "Content unavailable" in Files.app

   https://github.com/owncloud/ios-app/pull/1223

* Bugfix - Recent files view: [#1225](https://github.com/owncloud/ios-app/pull/1225)

   Added Quick Access item "Recents", which was missing in version 12.0.1

   https://github.com/owncloud/ios-app/pull/1225

* Bugfix - Attach files from third-party apps: [#1228](https://github.com/owncloud/ios-app/pull/1228)

   Attaching files in third-party apps via file provider were not possible, if file
   was not downloaded.

   https://github.com/owncloud/ios-app/pull/1228

# Changelog for ownCloud iOS Client [12.0.1] (2023-06-15)
The following sections list the changes in ownCloud iOS Client 12.0.1 relevant to
ownCloud admins and users.

[12.0.1]: https://github.com/owncloud/ios-app/compare/milestone/12.0.0...milestone/12.0.1

## Summary

* Bugfix - Several Bug Fixes: [#1220](https://github.com/owncloud/ios-app/pull/1220)

## Details

* Bugfix - Several Bug Fixes: [#1220](https://github.com/owncloud/ios-app/pull/1220)

   Fixed keyboard, media streaming, full screen mode, offline indicator, duplicated
   sharing option, and UI issues.

   https://github.com/owncloud/ios-app/pull/1220

# Changelog for ownCloud iOS Client [12.0.0] (2023-06-12)
The following sections list the changes in ownCloud iOS Client 12.0.0 relevant to
ownCloud admins and users.

[12.0.0]: https://github.com/owncloud/ios-app/compare/milestone/11.11.1...milestone/12.0.0

## Summary

* Change - Spaces/Drives / Graph API support: [#92](https://github.com/owncloud/ios-sdk/pull/92)
* Change - Gridview implementation: [#744](https://github.com/owncloud/ios-app/issues/744)
* Change - App Provider support: [#1127](https://github.com/owncloud/ios-app/issues/1127)
* Change - New Navigation: [#1162](https://github.com/owncloud/ios-app/pull/1162)
* Change - Postbuild Settings: [#1179](https://github.com/owncloud/ios-app/pull/1179)
* Change - CSS theming: [#1194](https://github.com/owncloud/ios-app/pull/1194)
* Change - Support saving folder searches: [#1205](https://github.com/owncloud/ios-app/pull/1205)
* Change - Unified Onboarding and Account Setup: [#1208](https://github.com/owncloud/ios-app/pull/1208)
* Change - New sharing UI with role support: [#4848](https://github.com/owncloud/ocis/issues/4848#issuecomment-1283678879)
* Change - Support Webfinger based lookup server: [#4849](https://github.com/owncloud/enterprise/issues/4849)
* Change - Added new build flag: [#5290](https://github.com/owncloud/enterprise/issues/5290)
* Change - Disallow Extensions via MDM: [#5308](https://github.com/owncloud/enterprise/issues/5308)
* Change - Disable access to File Provider via MDM: [#5371](https://github.com/owncloud/enterprise/issues/5371)
* Change - Dynamic Instance Logo: [#5505](https://github.com/owncloud/enterprise/issues/5505)

## Details

* Change - Spaces/Drives / Graph API support: [#92](https://github.com/owncloud/ios-sdk/pull/92)

   Adds support for spaces/drives / Graph API.

   https://github.com/owncloud/ios-sdk/pull/92

* Change - Gridview implementation: [#744](https://github.com/owncloud/ios-app/issues/744)

   Implements a dynamically adapting grid layout used for item grid view.

   https://github.com/owncloud/ios-app/issues/744

* Change - App Provider support: [#1127](https://github.com/owncloud/ios-app/issues/1127)

   Create and edit new documents through app providers on servers that support
   them.

   https://github.com/owncloud/ios-app/issues/1127

* Change - New Navigation: [#1162](https://github.com/owncloud/ios-app/pull/1162)

   Navigate via the new sidebar, breadcrumbs and browser controls.

   https://github.com/owncloud/ios-app/pull/1162

* Change - Postbuild Settings: [#1179](https://github.com/owncloud/ios-app/pull/1179)

   Postbuild settings allow modification of branding and class settings via URL
   scheme, allowing to quickly iterate during development without the need to
   rebuild the app.

   https://github.com/owncloud/ios-app/pull/1179

* Change - CSS theming: [#1194](https://github.com/owncloud/ios-app/pull/1194)

   ThemeCSS brings CSS-style styling to the UIViewController/UIView tree, by
   allowing to attach CSS-style selectors to them via new cssSelector and
   cssSelectors properties.

   https://github.com/owncloud/ios-app/pull/1194

* Change - Support saving folder searches: [#1205](https://github.com/owncloud/ios-app/pull/1205)

   Support for saving folder-scoped searches

   https://github.com/owncloud/ios-app/pull/1205

* Change - Unified Onboarding and Account Setup: [#1208](https://github.com/owncloud/ios-app/pull/1208)

   Migrated the branded onboarding process into the vanilla add account view.

   https://github.com/owncloud/ios-app/pull/1208

* Change - New sharing UI with role support: [#4848](https://github.com/owncloud/ocis/issues/4848#issuecomment-1283678879)

   New sharing UI with support for share roles and a modern layout.

   https://github.com/owncloud/ocis/issues/4848#issuecomment-1283678879

* Change - Support Webfinger based lookup server: [#4849](https://github.com/owncloud/enterprise/issues/4849)

   Allows using webfinger or a lookup table to locate and use an alternative server
   based on the user name.

   https://github.com/owncloud/enterprise/issues/4849

* Change - Added new build flag: [#5290](https://github.com/owncloud/enterprise/issues/5290)

   Add DISABLE_PLAIN_HTTP build flag

   https://github.com/owncloud/enterprise/issues/5290

* Change - Disallow Extensions via MDM: [#5308](https://github.com/owncloud/enterprise/issues/5308)

   Add option to disallow extensions, show action for unviewable filetypes

   https://github.com/owncloud/enterprise/issues/5308

* Change - Disable access to File Provider via MDM: [#5371](https://github.com/owncloud/enterprise/issues/5371)

   Adds a new MDM option fileprovider.browseable

   https://github.com/owncloud/enterprise/issues/5371

* Change - Dynamic Instance Logo: [#5505](https://github.com/owncloud/enterprise/issues/5505)

   Use the instance logo as account avatar logo.

   https://github.com/owncloud/enterprise/issues/5505

# Changelog for ownCloud iOS Client [11.11.1] (2022-10-30)
The following sections list the changes in ownCloud iOS Client 11.11.1 relevant to
ownCloud admins and users.

[11.11.1]: https://github.com/owncloud/ios-app/compare/milestone/11.11.0...milestone/11.11.1

## Summary

* Bugfix - Enabling Markup Mode: [#1141](https://github.com/owncloud/ios-app/issues/1141)

## Details

* Bugfix - Enabling Markup Mode: [#1141](https://github.com/owncloud/ios-app/issues/1141)

   Enabling markup mode crashed on iOS 16.

   https://github.com/owncloud/ios-app/issues/1141

# Changelog for ownCloud iOS Client [11.11.0] (2022-09-26)
The following sections list the changes in ownCloud iOS Client 11.11.0 relevant to
ownCloud admins and users.

[11.11.0]: https://github.com/owncloud/ios-app/compare/milestone/11.10.1...milestone/11.11.0

## Summary

* Bugfix - Respect privateLinks capability: [#1138](https://github.com/owncloud/ios-app/issues/1138)
* Bugfix - Enabling Markup Mode, Showing Video Controls on iOS 16, Updating Theme: [#1141](https://github.com/owncloud/ios-app/issues/1141)
* Bugfix - Share Extension Passcode Lock Interval: [#1156](https://github.com/owncloud/ios-app/issues/1156)
* Bugfix - Video Metadata Image: [#5296](https://github.com/owncloud/enterprise/issues/5296)
* Change - New Dark Mode Themes: [#1146](https://github.com/owncloud/ios-app/issues/1146)

## Details

* Bugfix - Respect privateLinks capability: [#1138](https://github.com/owncloud/ios-app/issues/1138)

   Respect files.privateLinks capability and do not offer to create private links
   when privateLinks are not supported.

   https://github.com/owncloud/ios-app/issues/1138

* Bugfix - Enabling Markup Mode, Showing Video Controls on iOS 16, Updating Theme: [#1141](https://github.com/owncloud/ios-app/issues/1141)

   Enabling markup mode was broken on iOS 16 because of rearranged navigation bar
   and toolbar items. Video player controls were not showing on iOS 16. Furthermore
   when a new theme was chosen, this causes that the UITabBar and UIToolbar does
   not updates colours.

   https://github.com/owncloud/ios-app/issues/1141

* Bugfix - Share Extension Passcode Lock Interval: [#1156](https://github.com/owncloud/ios-app/issues/1156)

   The passcode lock interval was not taken into use in the share extension.

   https://github.com/owncloud/ios-app/issues/1156

* Bugfix - Video Metadata Image: [#5296](https://github.com/owncloud/enterprise/issues/5296)

   If a video file includes a metadata image, the video file was not visible,
   because the metadata image was overlaying.

   https://github.com/owncloud/enterprise/issues/5296

* Change - New Dark Mode Themes: [#1146](https://github.com/owncloud/ios-app/issues/1146)

   Adds a new dark mode theme which is mostly equal to the web UI dark mode theme.
   Furthermore it adds a black dark mode theme.

   https://github.com/owncloud/ios-app/issues/1146

# Changelog for ownCloud iOS Client [11.10.1] (2022-08-02)
The following sections list the changes in ownCloud iOS Client 11.10.1 relevant to
ownCloud admins and users.

[11.10.1]: https://github.com/owncloud/ios-app/compare/milestone/11.10.0...milestone/11.10.1

## Summary

* Bugfix - (Branding) Biometrical Unlock in Share Sheet: [#1129](https://github.com/owncloud/ios-app/pull/1129)
* Bugfix - Show folder contents from cache when offline: [#1130](https://github.com/owncloud/ios-app/issues/1130)
* Bugfix - (Branding) Color Issues: [#1132](https://github.com/owncloud/ios-app/pull/1132)

## Details

* Bugfix - (Branding) Biometrical Unlock in Share Sheet: [#1129](https://github.com/owncloud/ios-app/pull/1129)

   Biometrical unlock in the share sheet does not work in some third party apps
   like Boxer. With new branding parameters it is now possible to disable
   biometrical unlock in the share sheet or to exclude specific apps.

   https://github.com/owncloud/ios-app/pull/1129

* Bugfix - Show folder contents from cache when offline: [#1130](https://github.com/owncloud/ios-app/issues/1130)

   With this fix the app shows the contents of the available folders when offline.

   https://github.com/owncloud/ios-app/issues/1130

* Bugfix - (Branding) Color Issues: [#1132](https://github.com/owncloud/ios-app/pull/1132)

   Fix some automatic color values, if the branding color is bright by checking the
   brightness of the color.

   https://github.com/owncloud/ios-app/pull/1132

# Changelog for ownCloud iOS Client [11.10.0] (2022-05-18)
The following sections list the changes in ownCloud iOS Client 11.10.0 relevant to
ownCloud admins and users.

[11.10.0]: https://github.com/owncloud/ios-app/compare/milestone/11.9.1...milestone/11.10.0

## Summary

* Bugfix - IOS 15 SDK: [#1066](https://github.com/owncloud/ios-app/issues/1066)
* Bugfix - EMM Shortcuts Licensing: [#1114](https://github.com/owncloud/ios-app/issues/1114)
* Bugfix - Increased Timeout for Copy Action: [#1119](https://github.com/owncloud/ios-app/issues/1119)
* Bugfix - Shortcuts Action Delete Path Item: [#1123](https://github.com/owncloud/ios-app/issues/1123)
* Change - Migration to OpenSSL 1.1.0: [#1116](https://github.com/owncloud/ios-app/pull/1116)

## Details

* Bugfix - IOS 15 SDK: [#1066](https://github.com/owncloud/ios-app/issues/1066)

   After upgrading to iOS 15 SDK some UI fixes were needed.

   https://github.com/owncloud/ios-app/issues/1066

* Bugfix - EMM Shortcuts Licensing: [#1114](https://github.com/owncloud/ios-app/issues/1114)

   If app was build as EMM version, the app shown an licensing error, when running
   shortcut intents.

   https://github.com/owncloud/ios-app/issues/1114

* Bugfix - Increased Timeout for Copy Action: [#1119](https://github.com/owncloud/ios-app/issues/1119)

   Increased HTTP request timeout for COPY actions from 1 minute to 10 minutes and
   improved error handling for request timeouts.

   https://github.com/owncloud/ios-app/issues/1119

* Bugfix - Shortcuts Action Delete Path Item: [#1123](https://github.com/owncloud/ios-app/issues/1123)

   The shortcuts action Delete Path Item did not provided configured accounts.

   https://github.com/owncloud/ios-app/issues/1123

* Change - Migration to OpenSSL 1.1.0: [#1116](https://github.com/owncloud/ios-app/pull/1116)

   Migrated code to OpenSSL 1.1.1 API.

   https://github.com/owncloud/ios-app/pull/1116

# Changelog for ownCloud iOS Client [11.9.1] (2022-03-29)
The following sections list the changes in ownCloud iOS Client 11.9.1 relevant to
ownCloud admins and users.

[11.9.1]: https://github.com/owncloud/ios-app/compare/milestone/11.9.0...milestone/11.9.1

## Summary

* Bugfix - Setup Passcode with Biometrical Unlock: [#1112](https://github.com/owncloud/ios-app/pull/1112)
* Change - Set App Group Identifier: [#1099](https://github.com/owncloud/ios-app/pull/1099)

## Details

* Bugfix - Setup Passcode with Biometrical Unlock: [#1112](https://github.com/owncloud/ios-app/pull/1112)

   Biometrical unlock button no longer appear in setup view and after passcode was
   successfully setup, show biometrical unlock for permissions dialog.

   https://github.com/owncloud/ios-app/pull/1112

* Change - Set App Group Identifier: [#1099](https://github.com/owncloud/ios-app/pull/1099)

   Set a custom app group identifier via Branding.plist this parameter. This value
   will be set by fastlane to all needed Info.plist keys. This is needed, if a
   customer is using an own resigning script which does not handle setting the app
   group identifier.

   https://github.com/owncloud/ios-app/pull/1099

# Changelog for ownCloud iOS Client [11.9.0] (2022-03-16)
The following sections list the changes in ownCloud iOS Client 11.9.0 relevant to
ownCloud admins and users.

[11.9.0]: https://github.com/owncloud/ios-app/compare/milestone/11.8.2...milestone/11.9.0

## Summary

* Bugfix - Fix WebDAV endpoint URL for media playback after restoration: [#1093](https://github.com/owncloud/ios-app/pull/1093)
* Bugfix - OAuth token renewal race condition: [#1105](https://github.com/owncloud/ios-app/pull/1105)
* Change - Infinite PROPFIND support: [#950](https://github.com/owncloud/ios-app/issues/950)
* Change - Rename Account (without re-authentication): [#972](https://github.com/owncloud/ios-app/issues/972)
* Change - Biometrical Authentication Button: [#1004](https://github.com/owncloud/ios-app/issues/1004)
* Change - Poll for changes efficiency enhancements: [#1043](https://github.com/owncloud/ios-app/pull/1043)
* Change - Webfinger / server location: [#1059](https://github.com/owncloud/ios-app/pull/1059)

## Details

* Bugfix - Fix WebDAV endpoint URL for media playback after restoration: [#1093](https://github.com/owncloud/ios-app/pull/1093)

   Fixes a bug where media playback failed with a 404 Not Found error after
   restoration because the WebDAV endpoint URL was constructed from authentication
   data rather than OC user endpoint data.

   https://github.com/owncloud/ios-app/pull/1093

* Bugfix - OAuth token renewal race condition: [#1105](https://github.com/owncloud/ios-app/pull/1105)

   Retry requests that failed with a 401 during a token refresh

   https://github.com/owncloud/ios-app/pull/1105

* Change - Infinite PROPFIND support: [#950](https://github.com/owncloud/ios-app/issues/950)

   Added support for prepopulation of newly created account bookmarks via infinite
   PROPFINDs, which speeds up the initial scan

   https://github.com/owncloud/ios-app/issues/950

* Change - Rename Account (without re-authentication): [#972](https://github.com/owncloud/ios-app/issues/972)

   Check if only the account name was changed in edit mode: save and dismiss
   without re-authentication

   https://github.com/owncloud/ios-app/issues/972

* Change - Biometrical Authentication Button: [#1004](https://github.com/owncloud/ios-app/issues/1004)

   Added biometrical authentication button to provide a fallback for the
   fileprovider or app, if the automatically biometrical unlock does not work, or
   the user cancel the biometrical authentication flow.

   https://github.com/owncloud/ios-app/issues/1004

* Change - Poll for changes efficiency enhancements: [#1043](https://github.com/owncloud/ios-app/pull/1043)

   Avoids simultaneous polling for changes by FileProvider and app.

   https://github.com/owncloud/ios-app/pull/1043

* Change - Webfinger / server location: [#1059](https://github.com/owncloud/ios-app/pull/1059)

   Allows using webfinger or a lookup table to locate and use an alternative server
   based on the user name

   https://github.com/owncloud/ios-app/pull/1059

# Changelog for ownCloud iOS Client [11.8.2] (2022-01-17)
The following sections list the changes in ownCloud iOS Client 11.8.2 relevant to
ownCloud admins and users.

[11.8.2]: https://github.com/owncloud/ios-app/compare/milestone/11.8.1...milestone/11.8.2

## Summary

* Bugfix - Continuous Audio Playback: [#4924](https://github.com/owncloud/enterprise/issues/4924)
* Bugfix - PDF Editing: [#4934](https://github.com/owncloud/enterprise/issues/4934)
* Change - (Branding) Corporate Color as Folder Color: [#1069](https://github.com/owncloud/ios-app/issues/1069)

## Details

* Bugfix - Continuous Audio Playback: [#4924](https://github.com/owncloud/enterprise/issues/4924)

   Fixed continuous audio playback, which stopped after two audio files.

   https://github.com/owncloud/enterprise/issues/4924

* Bugfix - PDF Editing: [#4934](https://github.com/owncloud/enterprise/issues/4934)

   Fixed bug that prevents changes to PDFs being saved in place.

   https://github.com/owncloud/enterprise/issues/4934

* Change - (Branding) Corporate Color as Folder Color: [#1069](https://github.com/owncloud/ios-app/issues/1069)

   Use the corporate color as folder color as default color (can be overridden by
   the specific key/value pair).

   https://github.com/owncloud/ios-app/issues/1069

# Changelog for ownCloud iOS Client [11.8.1] (2021-12-22)
The following sections list the changes in ownCloud iOS Client 11.8.1 relevant to
ownCloud admins and users.

[11.8.1]: https://github.com/owncloud/ios-app/compare/milestone/11.8.0...milestone/11.8.1

## Summary

* Change - Localized Sort Order: [#975](https://github.com/owncloud/ios-app/issues/975)
* Change - Fallback on OIDC Dynamic Client Registration: [#1068](https://github.com/owncloud/ios-app/pull/1068)

## Details

* Change - Localized Sort Order: [#975](https://github.com/owncloud/ios-app/issues/975)

   Improved sorting results and localized sorting across query results and database
   queries, via the SDK's new OCLOCALIZED collation and sort comparator.

   https://github.com/owncloud/ios-app/issues/975

* Change - Fallback on OIDC Dynamic Client Registration: [#1068](https://github.com/owncloud/ios-app/pull/1068)

   Adds authentication-oauth2.oidc-fallback-on-client-registration-failure -
   defaulting to true - to allow the automatic fallback to default client_id /
   client_secret if OpenID Connect Dynamic Client Registration fails with any
   error. Furthermore fixed an infinite OAuth2 token refresh loop via SDK update.

   https://github.com/owncloud/ios-app/pull/1068

# Changelog for ownCloud iOS Client [11.8.0] (2021-12-01)
The following sections list the changes in ownCloud iOS Client 11.8.0 relevant to
ownCloud admins and users.

[11.8.0]: https://github.com/owncloud/ios-app/compare/milestone/11.7.1...milestone/11.8.0

## Summary

* Bugfix - Background Location Settings: [#1050](https://github.com/owncloud/ios-app/issues/1050)
* Bugfix - Clear Passcode Lock: [#1061](https://github.com/owncloud/ios-app/pull/1061)
* Bugfix - Quick Access: [#4767](https://github.com/owncloud/enterprise/issues/4767)
* Bugfix - (Branding) Retry Section for Login Error: [#4786](https://github.com/owncloud/enterprise/issues/4786)
* Change - Account List: [#1014](https://github.com/owncloud/ios-app/issues/1014)
* Change - (Branding) Modular Localization: [#1054](https://github.com/owncloud/ios-app/pull/1054)
* Change - (Branding) Skip Account Screen: [#1056](https://github.com/owncloud/ios-app/pull/1056)
* Change - (Branding) Color and UI Improvements: [#1057](https://github.com/owncloud/ios-app/pull/1057)
* Change - Suggest Biometrical Unlock: [#4747](https://github.com/owncloud/enterprise/issues/4747)
* Change - (Branding) Default User Settings: [#4766](https://github.com/owncloud/enterprise/issues/4766)
* Change - Display Name: [#4798](https://github.com/owncloud/enterprise/issues/4798)
* Change - Licenses Overview: [#4801](https://github.com/owncloud/enterprise/issues/4801)
* Change - (Branding) Remove Code via Build Flag: [#4805](https://github.com/owncloud/enterprise/issues/4805)
* Change - (Branding) Biometrical Unlock Setting: [#4818](https://github.com/owncloud/enterprise/issues/4818)
* Change - (Branding) Custom App/Auth Schemes: [#4857](https://github.com/owncloud/enterprise/issues/4857)

## Details

* Bugfix - Background Location Settings: [#1050](https://github.com/owncloud/ios-app/issues/1050)

   Do not show the Background Location settings section, if no upload path was
   chosen.

   https://github.com/owncloud/ios-app/issues/1050

* Bugfix - Clear Passcode Lock: [#1061](https://github.com/owncloud/ios-app/pull/1061)

   Clear unlock and in case an unlock has expired, to protect against subsequent
   attempts setting the device time to an earlier date.

   https://github.com/owncloud/ios-app/pull/1061

* Bugfix - Quick Access: [#4767](https://github.com/owncloud/enterprise/issues/4767)

   Fix bug where a quick access entry showed no items when selected a second time.

   https://github.com/owncloud/enterprise/issues/4767

* Bugfix - (Branding) Retry Section for Login Error: [#4786](https://github.com/owncloud/enterprise/issues/4786)

   This adds a retry section to the branded login, e.g. if a server url could not
   be reached.

   https://github.com/owncloud/enterprise/issues/4786

* Change - Account List: [#1014](https://github.com/owncloud/ios-app/issues/1014)

   Show a new detailed single account view instead of the server list if only one
   account is configured.

   https://github.com/owncloud/ios-app/issues/1014

* Change - (Branding) Modular Localization: [#1054](https://github.com/owncloud/ios-app/pull/1054)

   Allowing complex customization of localized strings with variables, value
   sources and complete text replacements.

   https://github.com/owncloud/ios-app/pull/1054

* Change - (Branding) Skip Account Screen: [#1056](https://github.com/owncloud/ios-app/pull/1056)

   Skip "Manage" screen / automatically open "Files" screen after login via
   branding parameter.

   https://github.com/owncloud/ios-app/pull/1056

* Change - (Branding) Color and UI Improvements: [#1057](https://github.com/owncloud/ios-app/pull/1057)

   Setup a branding with only two color values and simplified a lot of branding
   values and furthermore fixed some UI issues.

   https://github.com/owncloud/ios-app/pull/1057

* Change - Suggest Biometrical Unlock: [#4747](https://github.com/owncloud/enterprise/issues/4747)

   Suggest enabling biometrical unlock after setting up passcode protection.

   https://github.com/owncloud/enterprise/issues/4747

* Change - (Branding) Default User Settings: [#4766](https://github.com/owncloud/enterprise/issues/4766)

   Adds a new class setting to allow registration of alternative defaults for user
   defaults.

   https://github.com/owncloud/enterprise/issues/4766

* Change - Display Name: [#4798](https://github.com/owncloud/enterprise/issues/4798)

   Show display name in branded single account view if available, otherwise show
   the userName.

   https://github.com/owncloud/enterprise/issues/4798

* Change - Licenses Overview: [#4801](https://github.com/owncloud/enterprise/issues/4801)

   Add a new view controller to present license texts for each component
   individually.

   https://github.com/owncloud/enterprise/issues/4801

* Change - (Branding) Remove Code via Build Flag: [#4805](https://github.com/owncloud/enterprise/issues/4805)

   Adds support for disable code via parameters which can be specified via
   Branding.plist.

   https://github.com/owncloud/enterprise/issues/4805

* Change - (Branding) Biometrical Unlock Setting: [#4818](https://github.com/owncloud/enterprise/issues/4818)

   Control via branding parameter to auto enable biometrical unlock and immediately
   show Face ID authorization after the feature was enabled.

   https://github.com/owncloud/enterprise/issues/4818

* Change - (Branding) Custom App/Auth Schemes: [#4857](https://github.com/owncloud/enterprise/issues/4857)

   New branding parameter to change the schemes for private links and auth scheme.

   https://github.com/owncloud/enterprise/issues/4857

# Changelog for ownCloud iOS Client [11.7.1] (2021-09-22)
The following sections list the changes in ownCloud iOS Client 11.7.1 relevant to
ownCloud admins and users.

[11.7.1]: https://github.com/owncloud/ios-app/compare/milestone/11.7.0...milestone/11.7.1

## Summary

* Bugfix - (PDF-Viewer) Keyboard does not disappear: [#894](https://github.com/owncloud/ios-app/issues/894)
* Bugfix - Enabling Markup Edit Mode on iOS 15: [#1012](https://github.com/owncloud/ios-app/issues/1012)
* Bugfix - Automatic photo upload crash on iOS 15: [#1017](https://github.com/owncloud/ios-app/pull/1017)
* Bugfix - Open Private Link in Branded Client: [#1031](https://github.com/owncloud/ios-app/issues/1031)
* Bugfix - Open Private Link in Branded App: [#1031](https://github.com/owncloud/ios-app/issues/1031)
* Bugfix - (PDF-Viewer) "Go to page" action does not open last page: [#1033](https://github.com/owncloud/ios-app/issues/1033)
* Bugfix - (Branding) iOS 12 crash when entering Settings: [#4701](https://github.com/owncloud/enterprise/issues/4701)
* Change - (Branding) Add build flags support: [#1026](https://github.com/owncloud/ios-app/pull/1026)
* Change - Added associated domains to resign script: [#1028](https://github.com/owncloud/ios-app/pull/1028)
* Change - (Branding) Send Feedback via URL: [#1035](https://github.com/owncloud/ios-app/pull/1035)
* Change - (Branding) Option to disable file imports: [#4709](https://github.com/owncloud/enterprise/issues/4709)
* Change - (Branding) New Color Parameters: [#4716](https://github.com/owncloud/enterprise/issues/4716)
* Change - MDM-configurable App Lock Interval: [#4741](https://github.com/owncloud/enterprise/issues/4741)
* Change - Configurable poll interval: [#8777](https://github.com/owncloud/client/pull/8777)

## Details

* Bugfix - (PDF-Viewer) Keyboard does not disappear: [#894](https://github.com/owncloud/ios-app/issues/894)

   Keyboard does not disappear when using the "Go to page" action on the iPad.

   https://github.com/owncloud/ios-app/issues/894

* Bugfix - Enabling Markup Edit Mode on iOS 15: [#1012](https://github.com/owncloud/ios-app/issues/1012)

   Auto-enabling the markup edit mode on iOS 15 was broken.

   https://github.com/owncloud/ios-app/issues/1012

* Bugfix - Automatic photo upload crash on iOS 15: [#1017](https://github.com/owncloud/ios-app/pull/1017)

   On iOS 15, automatic photo upload seems to consume more resources than are
   available, leading to a crash. This pull requests reduces the number of
   concurrent photo upload operations from `available cores` to `1`.

   https://github.com/owncloud/ios-app/pull/1017

* Bugfix - Open Private Link in Branded Client: [#1031](https://github.com/owncloud/ios-app/issues/1031)

   This PR fixes a bug, when trying to open a private link via the custom url
   scheme `owncloud://` or via associated domains `applinks:`. Resolving a private
   link opened via the URL scheme owncloud:// was not successful in some cases.

   https://github.com/owncloud/ios-app/issues/1031

* Bugfix - Open Private Link in Branded App: [#1031](https://github.com/owncloud/ios-app/issues/1031)

   Private links will now be opened in detail view, if the app client is branded.

   https://github.com/owncloud/ios-app/issues/1031

* Bugfix - (PDF-Viewer) "Go to page" action does not open last page: [#1033](https://github.com/owncloud/ios-app/issues/1033)

   The last page of a PDF file could not be opened with the "Go to page" action.

   https://github.com/owncloud/ios-app/issues/1033

* Bugfix - (Branding) iOS 12 crash when entering Settings: [#4701](https://github.com/owncloud/enterprise/issues/4701)

   Addresses an issue where a branded build of the app crashes on iOS 12 upon
   entering Settings.

   https://github.com/owncloud/enterprise/issues/4701

* Change - (Branding) Add build flags support: [#1026](https://github.com/owncloud/ios-app/pull/1026)

   Add support for app build flags to enable/disable features at compile time via
   branding parameters

   https://github.com/owncloud/ios-app/pull/1026

* Change - Added associated domains to resign script: [#1028](https://github.com/owncloud/ios-app/pull/1028)

   Resign script can now inject associated domains into the resigned application's
   entitlements.

   https://github.com/owncloud/ios-app/pull/1028

* Change - (Branding) Send Feedback via URL: [#1035](https://github.com/owncloud/ios-app/pull/1035)

   Currently feedback could only be provided via email. Now it is possible to
   define a feedback url in a branded client.

   https://github.com/owncloud/ios-app/pull/1035

* Change - (Branding) Option to disable file imports: [#4709](https://github.com/owncloud/enterprise/issues/4709)

   Adds a new MDM option `branding.disabled-import-methods` to disable import
   methods

   https://github.com/owncloud/enterprise/issues/4709

* Change - (Branding) New Color Parameters: [#4716](https://github.com/owncloud/enterprise/issues/4716)

   Adds additional possibilities and simplifications for branding colors.

   https://github.com/owncloud/enterprise/issues/4716

* Change - MDM-configurable App Lock Interval: [#4741](https://github.com/owncloud/enterprise/issues/4741)

   New MDM / class setting option `passcode.lockDelay` to enforce locking after `N`
   seconds.

   https://github.com/owncloud/enterprise/issues/4741

* Change - Configurable poll interval: [#8777](https://github.com/owncloud/client/pull/8777)

   Add support for configurable poll interval via capabilities.php and MDM.

   https://github.com/owncloud/client/pull/8777

# Changelog for ownCloud iOS Client [11.7.0] (2021-07-29)
The following sections list the changes in ownCloud iOS Client 11.7.0 relevant to
ownCloud admins and users.

[11.7.0]: https://github.com/owncloud/ios-app/compare/milestone/11.6.1...milestone/11.7.0

## Summary

* Change - Clipboard Support: [#514](https://github.com/owncloud/ios-app/pull/514)
* Change - Background Media Upload: [#958](https://github.com/owncloud/ios-app/pull/958)
* Change - Six Digits Passcode: [#958](https://github.com/owncloud/ios-app/pull/958)
* Change - Filename Layout: [#968](https://github.com/owncloud/ios-app/issues/968)

## Details

* Change - Clipboard Support: [#514](https://github.com/owncloud/ios-app/pull/514)

   Clipboard support provides the following new features: - Copy: Files can be
   copied to the system-wide clipboard and pasted into other apps. Folders can also
   be copied within the ownCloud app. - Paste: Files can be pasted from the
   system-wide clipboard into the ownCloud app. Likewise, files and folders copied
   within the app can be pasted. - Cut: Within an ownCloud account, files and
   folders can be cut and pasted to a different path. After this action, the items
   are no longer present in the original location.

   https://github.com/owncloud/ios-app/pull/514

* Change - Background Media Upload: [#958](https://github.com/owncloud/ios-app/pull/958)

   Uploading new media files is now more reliable in the background when "Use
   background location updates" is enabled in the settings.

   https://github.com/owncloud/ios-app/pull/958

* Change - Six Digits Passcode: [#958](https://github.com/owncloud/ios-app/pull/958)

   Passcode lock supports to set a passcode lock with 4 or 6 digits.

   https://github.com/owncloud/ios-app/pull/958

* Change - Filename Layout: [#968](https://github.com/owncloud/ios-app/issues/968)

   Adopted the filename layout to the new Web UI with bold font weight, large file
   name and normal font weight, small file extension.

   https://github.com/owncloud/ios-app/issues/968

# Changelog for ownCloud iOS Client [11.6.1] (2021-06-24)
The following sections list the changes in ownCloud iOS Client 11.6.1 relevant to
ownCloud admins and users.

[11.6.1]: https://github.com/owncloud/ios-app/compare/milestone/11.6.0...milestone/11.6.1

## Summary

* Bugfix - FileProvider UI on iOS 12: [#986](https://github.com/owncloud/ios-app/issues/986)
* Bugfix - In some cases, background media upload worked not as expected: [#4547](https://github.com/owncloud/enterprise/issues/4547)
* Bugfix - Fixed misleading warnings at let's encrypt cert renewal: [#4558](https://github.com/owncloud/enterprise/issues/4558)
* Change - Additional URL Scheme: [#979](https://github.com/owncloud/ios-app/issues/979)

## Details

* Bugfix - FileProvider UI on iOS 12: [#986](https://github.com/owncloud/ios-app/issues/986)

   Views in FileProvider UI (public links, share with user) could not be dismissed
   on iOS 12

   https://github.com/owncloud/ios-app/issues/986

* Bugfix - In some cases, background media upload worked not as expected: [#4547](https://github.com/owncloud/enterprise/issues/4547)

   https://github.com/owncloud/enterprise/issues/4547

* Bugfix - Fixed misleading warnings at let's encrypt cert renewal: [#4558](https://github.com/owncloud/enterprise/issues/4558)

   https://github.com/owncloud/enterprise/issues/4558

* Change - Additional URL Scheme: [#979](https://github.com/owncloud/ios-app/issues/979)

   Added an additional URL scheme to open a specific app, if more than one ownCloud
   apps are installed with different bundle IDs. (owncloud-app, owncloud-emm or
   owncloud-online)

   https://github.com/owncloud/ios-app/issues/979

# Changelog for ownCloud iOS Client [11.6.0] (2021-05-12)
The following sections list the changes in ownCloud iOS Client 11.6.0 relevant to
ownCloud admins and users.

[11.6.0]: https://github.com/owncloud/ios-app/compare/milestone/11.5.2...milestone/11.6.0

## Summary

* Bugfix - Improved AppStore Review Request Time: [#845](https://github.com/owncloud/ios-app/pull/845)
* Bugfix - Changed wording in documentation: [#867](https://github.com/owncloud/ios-app/pull/867)
* Bugfix - Fix bookmark name editing: [#877](https://github.com/owncloud/ios-app/pull/877)
* Bugfix - Media Player Behaviour: [#884](https://github.com/owncloud/ios-app/pull/884)
* Bugfix - Japanese Input Support: [#916](https://github.com/owncloud/ios-app/issues/916)
* Bugfix - Swiping PDF thumbnail view on the iPhone: [#918](https://github.com/owncloud/ios-app/issues/918)
* Bugfix - Added Dark Mode Support to Preview: [#919](https://github.com/owncloud/ios-app/issues/919)
* Bugfix - Passcode Settings Section: [#923](https://github.com/owncloud/ios-app/issues/923)
* Bugfix - Viewer fixes, refactoring and minor improvements: [#942](https://github.com/owncloud/ios-app/issues/942)
* Bugfix - Disable Markup Action for Mime-Type Gif: [#952](https://github.com/owncloud/ios-app/issues/952)
* Bugfix - UI refinements in action card: [#956](https://github.com/owncloud/ios-app/issues/956)
* Bugfix - State Restoration for Branded Login: [#957](https://github.com/owncloud/ios-app/issues/957)
* Bugfix - Added paragraph on top of Acknowledgements page: [#4284](https://github.com/owncloud/enterprise/issues/4284)
* Bugfix - Fixed Branded UI on iPad: [#4367](https://github.com/owncloud/enterprise/issues/4367)
* Bugfix - Enabling Markup Mode: [#4468](https://github.com/owncloud/enterprise/issues/4468)
* Change - Local account-wide search using custom queries: [#53](https://github.com/owncloud/ios-app/issues/53)
* Change - Full Screen PDF View: [#428](https://github.com/owncloud/ios-app/issues/428)
* Change - Unified Branding with MDM support: [#697](https://github.com/owncloud/ios-app/issues/697)
* Change - Presentation Mode: [#704](https://github.com/owncloud/ios-app/issues/704)
* Change - Class Settings Metadata Support: [#831](https://github.com/owncloud/ios-app/issues/831)
* Change - Video upload improvements: [#847](https://github.com/owncloud/ios-app/issues/847)
* Change - Enhanced drag & drop support: [#850](https://github.com/owncloud/ios-app/pull/850)
* Change - New photo picker / permissions model for iOS 14: [#851](https://github.com/owncloud/ios-app/issues/851)
* Change - Shortcut uploads and error handling improvements: [#858](https://github.com/owncloud/ios-app/issues/858)
* Change - Corporate Color + UI Refinements: [#860](https://github.com/owncloud/ios-app/issues/860)
* Change - Improved Right-to-Left Language UI-Design: [#861](https://github.com/owncloud/ios-app/issues/861)
* Change - Enforce User ID when updating token-based bookmarks: [#869](https://github.com/owncloud/ios-app/pull/869)
* Change - TLS certificate comparison: [#872](https://github.com/owncloud/ios-app/pull/872)
* Change - New Issue view / presentation: [#874](https://github.com/owncloud/ios-app/pull/874)
* Change - Automated Calens Changelog Creation: [#879](https://github.com/owncloud/ios-app/pull/879)
* Change - File Provider Passcode Protection: [#880](https://github.com/owncloud/ios-app/issues/880)
* Change - Updated Keyboard Shortcuts: [#902](https://github.com/owncloud/ios-app/issues/902)
* Change - Added Actions to File Provider: Sharing & Public Links: [#910](https://github.com/owncloud/ios-app/pull/910)
* Change - MDM Enhancements: [#4104](https://github.com/owncloud/enterprise/issues/4104)
* Change - "Go to Page" reallocated in PDF previews: [#4448](https://github.com/owncloud/enterprise/issues/4448)
* Change - French Localization: [#4450](https://github.com/owncloud/enterprise/issues/4450)

## Details

* Bugfix - Improved AppStore Review Request Time: [#845](https://github.com/owncloud/ios-app/pull/845)

   Changed request time for In-App review and fixed storing the first launch date

   https://github.com/owncloud/ios-app/pull/845

* Bugfix - Changed wording in documentation: [#867](https://github.com/owncloud/ios-app/pull/867)

   Changed wording so it no longer suggests username is editable

   https://github.com/owncloud/ios-app/pull/867

* Bugfix - Fix bookmark name editing: [#877](https://github.com/owncloud/ios-app/pull/877)

   When editing bookmarks:

   - if a name was set, it wasn't shown in the edit interface - bookmark name
   edits/additions would get lost - bookmark name edits would not be presented in
   the list unless scrolling out of view and back in

   https://github.com/owncloud/ios-app/pull/877

* Bugfix - Media Player Behaviour: [#884](https://github.com/owncloud/ios-app/pull/884)

   Fix for an issue when playing multiple items in the same directory. If e.g.
   image item is the next one, multi media playback would stop.

   https://github.com/owncloud/ios-app/pull/884

* Bugfix - Japanese Input Support: [#916](https://github.com/owncloud/ios-app/issues/916)

   Fixed a problem in scan view when renaming the file name and using a Japanese
   keyboard layout (2-Byte character). After entering a character inside the file
   name the text cursor jumped to the end.

   https://github.com/owncloud/ios-app/issues/916

* Bugfix - Swiping PDF thumbnail view on the iPhone: [#918](https://github.com/owncloud/ios-app/issues/918)

   Prevent page container scrolling, when try to scroll inside the pdf thumbnail
   view on the iPhone

   https://github.com/owncloud/ios-app/issues/918

* Bugfix - Added Dark Mode Support to Preview: [#919](https://github.com/owncloud/ios-app/issues/919)

   Dark mode for QLPreviewController only worked, when system dark mode was used.
   Custom dark mode theme was not able set the dark mode style before.

   https://github.com/owncloud/ios-app/issues/919

* Bugfix - Passcode Settings Section: [#923](https://github.com/owncloud/ios-app/issues/923)

   If a passcode was enabled or disabled in the settings, the UI section was not
   updated.

   https://github.com/owncloud/ios-app/issues/923

* Bugfix - Viewer fixes, refactoring and minor improvements: [#942](https://github.com/owncloud/ios-app/issues/942)

   - fix for items, which could not be opened - new refresh policy: asks the user
   before updating PDF files

   https://github.com/owncloud/ios-app/issues/942

* Bugfix - Disable Markup Action for Mime-Type Gif: [#952](https://github.com/owncloud/ios-app/issues/952)

   Images with mime type image/gif can not edited with markup action and needs to
   be disabled.

   https://github.com/owncloud/ios-app/issues/952

* Bugfix - UI refinements in action card: [#956](https://github.com/owncloud/ios-app/issues/956)

   Fixed the corner radius. For larger UI width set a maximum width for the
   cardview and center the view.

   https://github.com/owncloud/ios-app/issues/956

* Bugfix - State Restoration for Branded Login: [#957](https://github.com/owncloud/ios-app/issues/957)

   State restoration was not working for branded clients. This fix will restore the
   last shown item after an app restart for branded clients.

   https://github.com/owncloud/ios-app/issues/957

* Bugfix - Added paragraph on top of Acknowledgements page: [#4284](https://github.com/owncloud/enterprise/issues/4284)

   - adds a paragraph on top of the Acknowledgements to provide additional context
   - adds PLCrashReporter license to acknowledgements

   https://github.com/owncloud/enterprise/issues/4284

* Bugfix - Fixed Branded UI on iPad: [#4367](https://github.com/owncloud/enterprise/issues/4367)

   - UI fix for branded login on the iPad - Fill color for branded button was not
   used

   https://github.com/owncloud/enterprise/issues/4367
   https://github.com/owncloud/enterprise/issues/4366

* Bugfix - Enabling Markup Mode: [#4468](https://github.com/owncloud/enterprise/issues/4468)

   In some cases enabling markup mode failed.

   https://github.com/owncloud/enterprise/issues/4468

* Change - Local account-wide search using custom queries: [#53](https://github.com/owncloud/ios-app/issues/53)

   User can switch between local folder or local account-wide search. Search terms
   and filter keywords can be combined inside the search field to get granular
   search results.

   https://github.com/owncloud/ios-app/issues/53

* Change - Full Screen PDF View: [#428](https://github.com/owncloud/ios-app/issues/428)

   - A PDF file can be opened in fullscreen view and hides unnecessary UI elements.
   (Tap to trigger full screen view) - Thumbnails positioned based on vertical size
   class after rotating the device to give the displayed document more screen real
   estate.

   https://github.com/owncloud/ios-app/issues/428

* Change - Unified Branding with MDM support: [#697](https://github.com/owncloud/ios-app/issues/697)

   Refactored Branding, introducing a new Branding class, unifying branding support
   with class settings while offering support for the legacy format and laying the
   ground for retrieving branding assets from a remote server.

   https://github.com/owncloud/ios-app/issues/697
   https://github.com/owncloud/ios-app/issues/792

* Change - Presentation Mode: [#704](https://github.com/owncloud/ios-app/issues/704)

   Added an action in detail view menu which enables presentation mode.
   Presentation mode prevents the display from sleep mode as long as the detail
   view is closed, furthermore the preview will be opened in full screen.

   https://github.com/owncloud/ios-app/issues/704

* Change - Class Settings Metadata Support: [#831](https://github.com/owncloud/ios-app/issues/831)

   Support for class settings metadata.

   https://github.com/owncloud/ios-app/issues/831

* Change - Video upload improvements: [#847](https://github.com/owncloud/ios-app/issues/847)

   - Added ability to upload slo-mo videos etc - Added option to allow uploading
   original videos

   https://github.com/owncloud/ios-app/issues/847

* Change - Enhanced drag & drop support: [#850](https://github.com/owncloud/ios-app/pull/850)

   Fix drag and drop and improve support to run the iOS app on M1 Macs:

   - add drag-out support for files that are not locally available yet - improve
   drag-in support for files, picking the best available representation that can be
   retrieved as data - support for drag & drop in the log file browser

   https://github.com/owncloud/ios-app/pull/850

* Change - New photo picker / permissions model for iOS 14: [#851](https://github.com/owncloud/ios-app/issues/851)

   - Using new PHPhotoPicker introduced in iOS14 instead of our custom picker. -
   Dealing with the photo permission model introduced in iOS14 where user can grant
   access just to specific photo assets or albums

   https://github.com/owncloud/ios-app/issues/851

* Change - Shortcut uploads and error handling improvements: [#858](https://github.com/owncloud/ios-app/issues/858)

   Improved error handling for Shortcut actions and now also reporting
   authentication errors. Added an optional "Wait for completion" option to the
   "Save File" and "Create Folder" action.

   https://github.com/owncloud/ios-app/issues/858

* Change - Corporate Color + UI Refinements: [#860](https://github.com/owncloud/ios-app/issues/860)

   The corporate color of the UI themes was updated and furthermore some colors was
   adopted for a better contrast. This PR includes also some refinements for some
   UI elements.

   https://github.com/owncloud/ios-app/issues/860

* Change - Improved Right-to-Left Language UI-Design: [#861](https://github.com/owncloud/ios-app/issues/861)

   Fixed missing views, which missed Right-to-Left language support.

   https://github.com/owncloud/ios-app/issues/861

* Change - Enforce User ID when updating token-based bookmarks: [#869](https://github.com/owncloud/ios-app/pull/869)

   This PR requires the user ID to remain the same when updating token-based
   bookmarks. If the user logs in as a user other than the one with which the
   bookmark was originally created, an error will be presented.

   https://github.com/owncloud/ios-app/pull/869

* Change - TLS certificate comparison: [#872](https://github.com/owncloud/ios-app/pull/872)

   When logging into an account and experiencing a different certificate that does
   not fulfill the rules for automatic acceptance as replacement, the issue it
   brings up now shows the differences between the two certificates to allow an
   informed decision by the user.

   https://github.com/owncloud/ios-app/pull/872

* Change - New Issue view / presentation: [#874](https://github.com/owncloud/ios-app/pull/874)

   As fixing an iPad layout issue in the old issues view proved too cumbersome,
   I've replaced the entire implementation with a new issue view, based on code
   already there and in use for cards and tables.

   https://github.com/owncloud/ios-app/pull/874

* Change - Automated Calens Changelog Creation: [#879](https://github.com/owncloud/ios-app/pull/879)

   This PR uses GitHub Actions to automatically generate a changelog file with
   Calens and commits the new CHANGELOG.md into the current branch.

   https://github.com/owncloud/ios-app/pull/879

* Change - File Provider Passcode Protection: [#880](https://github.com/owncloud/ios-app/issues/880)

   If the app is protected with a passcode the file provider extension will present
   an user interface for direct unlocking.

   https://github.com/owncloud/ios-app/issues/880

* Change - Updated Keyboard Shortcuts: [#902](https://github.com/owncloud/ios-app/issues/902)

   Added keyboard shortcuts in PDF view, media playback can now completely
   controlled by the keyboard and fixed broken keyboard commands.

   https://github.com/owncloud/ios-app/issues/902

* Change - Added Actions to File Provider: Sharing & Public Links: [#910](https://github.com/owncloud/ios-app/pull/910)

   Added file provider actions for Sharing and Public Links, which will open the UI
   for adding and editing sharing and public links to the selected item directly
   from the file provider.

   https://github.com/owncloud/ios-app/pull/910

* Change - MDM Enhancements: [#4104](https://github.com/owncloud/enterprise/issues/4104)

   - Passcode lock enforcement via class setting. User can be forced to set-up a
   passcode when he first starts the app - Auto-generated MDM documentation

   https://github.com/owncloud/enterprise/issues/4104

* Change - "Go to Page" reallocated in PDF previews: [#4448](https://github.com/owncloud/enterprise/issues/4448)

   The "Go to Page" option for PDF files has been reallocated to the Actions menu,
   and is also available by tapping on the page label.

   https://github.com/owncloud/enterprise/issues/4448

* Change - French Localization: [#4450](https://github.com/owncloud/enterprise/issues/4450)

   Added french localization.

   https://github.com/owncloud/enterprise/issues/4450

# Changelog for ownCloud iOS Client [11.5.2] (2021-03-03)
The following sections list the changes in ownCloud iOS Client 11.5.2 relevant to
ownCloud admins and users.

[11.5.2]: https://github.com/owncloud/ios-app/compare/milestone/11.5.1...milestone/11.5.2

## Summary

* Bugfix - PDF thumbnail view position on the iPad: [#905](https://github.com/owncloud/ios-app/pull/905)
* Bugfix - Misplaced Collapsible Progress Bar in detail view: [#906](https://github.com/owncloud/ios-app/issues/906)
* Bugfix - Accessing hyperlinks in PDF documents: [#4432](https://github.com/owncloud/enterprise/issues/4432)

## Details

* Bugfix - PDF thumbnail view position on the iPad: [#905](https://github.com/owncloud/ios-app/pull/905)

   Fixed the position of the PDF thumbnail view on the iPad from the bottom to the
   right position to get more visible PDF content and to prevent enabling the iOS
   app switcher when scrolling throw the thumbnail view.

   https://github.com/owncloud/ios-app/pull/905

* Bugfix - Misplaced Collapsible Progress Bar in detail view: [#906](https://github.com/owncloud/ios-app/issues/906)

   Hide the Collapsible Progress Bar in detail view and fixed position in file
   list.

   https://github.com/owncloud/ios-app/issues/906

* Bugfix - Accessing hyperlinks in PDF documents: [#4432](https://github.com/owncloud/enterprise/issues/4432)

   Tap on hyperlinks in PDF documents opens the link.

   https://github.com/owncloud/enterprise/issues/4432

# Changelog for ownCloud iOS Client [11.5.1] (2021-02-17)
The following sections list the changes in ownCloud iOS Client 11.5.1 relevant to
ownCloud admins and users.

[11.5.1]: https://github.com/owncloud/ios-app/compare/milestone/11.5.0...milestone/11.5.1

## Summary

* Bugfix - Fix Crash on iOS 12 devices: [#896](https://github.com/owncloud/ios-app/pull/896)

## Details

* Bugfix - Fix Crash on iOS 12 devices: [#896](https://github.com/owncloud/ios-app/pull/896)

   Fixed a crash on startup, when iOS 12 is installed on the device.

   https://github.com/owncloud/ios-app/pull/896

# Changelog for ownCloud iOS Client [11.5.0] (2021-02-10)
The following sections list the changes in ownCloud iOS Client 11.5.0 relevant to
ownCloud admins and users.

[11.5.0]: https://github.com/owncloud/ios-app/compare/milestone/11.5.0...milestone/11.5.0

## Summary

* Bugfix - Improved AppStore Review Request Time: [#845](https://github.com/owncloud/ios-app/pull/845)
* Bugfix - Changed wording in documentation: [#867](https://github.com/owncloud/ios-app/pull/867)
* Bugfix - Fix bookmark name editing: [#877](https://github.com/owncloud/ios-app/pull/877)
* Bugfix - Media Player Behaviour: [#884](https://github.com/owncloud/ios-app/pull/884)
* Bugfix - Added paragraph on top of Acknowledgements page: [#4284](https://github.com/owncloud/enterprise/issues/4284)
* Bugfix - Fixed Branded UI on iPad: [#4367](https://github.com/owncloud/enterprise/issues/4367)
* Change - Full Screen PDF View: [#428](https://github.com/owncloud/ios-app/issues/428)
* Change - Unified Branding with MDM support: [#697](https://github.com/owncloud/ios-app/issues/697)
* Change - Class Settings Metadata Support: [#831](https://github.com/owncloud/ios-app/issues/831)
* Change - Video upload improvements: [#847](https://github.com/owncloud/ios-app/issues/847)
* Change - Enhanced drag & drop support: [#850](https://github.com/owncloud/ios-app/pull/850)
* Change - New photo picker / permissions model for iOS 14: [#851](https://github.com/owncloud/ios-app/issues/851)
* Change - Corporate Color + UI Refinements: [#860](https://github.com/owncloud/ios-app/issues/860)
* Change - Improved Right-to-Left Language UI-Design: [#861](https://github.com/owncloud/ios-app/issues/861)
* Change - Enforce User ID when updating token-based bookmarks: [#869](https://github.com/owncloud/ios-app/pull/869)
* Change - TLS certificate comparison: [#872](https://github.com/owncloud/ios-app/pull/872)
* Change - New Issue view / presentation: [#874](https://github.com/owncloud/ios-app/pull/874)
* Change - Automated Calens Changelog Creation: [#879](https://github.com/owncloud/ios-app/pull/879)
* Change - MDM Enhancements: [#4104](https://github.com/owncloud/enterprise/issues/4104)

## Details

* Bugfix - Improved AppStore Review Request Time: [#845](https://github.com/owncloud/ios-app/pull/845)

   Changed request time for In-App review and fixed storing the first launch date

   https://github.com/owncloud/ios-app/pull/845

* Bugfix - Changed wording in documentation: [#867](https://github.com/owncloud/ios-app/pull/867)

   Changed wording so it no longer suggests username is editable

   https://github.com/owncloud/ios-app/pull/867

* Bugfix - Fix bookmark name editing: [#877](https://github.com/owncloud/ios-app/pull/877)

   When editing bookmarks:

   - if a name was set, it wasn't shown in the edit interface - bookmark name
   edits/additions would get lost - bookmark name edits would not be presented in
   the list unless scrolling out of view and back in

   https://github.com/owncloud/ios-app/pull/877

* Bugfix - Media Player Behaviour: [#884](https://github.com/owncloud/ios-app/pull/884)

   Fix for an issue when playing multiple items in the same directory. If e.g.
   image item is the next one, multi media playback would stop.

   https://github.com/owncloud/ios-app/pull/884

* Bugfix - Added paragraph on top of Acknowledgements page: [#4284](https://github.com/owncloud/enterprise/issues/4284)

   - adds a paragraph on top of the Acknowledgements to provide additional context
   - adds PLCrashReporter license to acknowledgements

   https://github.com/owncloud/enterprise/issues/4284

* Bugfix - Fixed Branded UI on iPad: [#4367](https://github.com/owncloud/enterprise/issues/4367)

   - UI fix for branded login on the iPad - Fill color for branded button was not
   used

   https://github.com/owncloud/enterprise/issues/4367
   https://github.com/owncloud/enterprise/issues/4366

* Change - Full Screen PDF View: [#428](https://github.com/owncloud/ios-app/issues/428)

   - A PDF file can be opened in fullscreen view and hides unnecessary UI elements.
   (Tap to trigger full screen view) - Thumbnails positioned based on vertical size
   class after rotating the device to give the displayed document more screen real
   estate.

   https://github.com/owncloud/ios-app/issues/428

* Change - Unified Branding with MDM support: [#697](https://github.com/owncloud/ios-app/issues/697)

   Refactored Branding, introducing a new Branding class, unifying branding support
   with class settings while offering support for the legacy format and laying the
   ground for retrieving branding assets from a remote server.

   https://github.com/owncloud/ios-app/issues/697
   https://github.com/owncloud/ios-app/issues/792

* Change - Class Settings Metadata Support: [#831](https://github.com/owncloud/ios-app/issues/831)

   Support for class settings metadata.

   https://github.com/owncloud/ios-app/issues/831

* Change - Video upload improvements: [#847](https://github.com/owncloud/ios-app/issues/847)

   - Added ability to upload slo-mo videos etc - Added option to allow uploading
   original videos

   https://github.com/owncloud/ios-app/issues/847

* Change - Enhanced drag & drop support: [#850](https://github.com/owncloud/ios-app/pull/850)

   Fix drag and drop and improve support to run the iOS app on M1 Macs:

   - add drag-out support for files that are not locally available yet - improve
   drag-in support for files, picking the best available representation that can be
   retrieved as data - support for drag & drop in the log file browser

   https://github.com/owncloud/ios-app/pull/850

* Change - New photo picker / permissions model for iOS 14: [#851](https://github.com/owncloud/ios-app/issues/851)

   - Using new PHPhotoPicker introduced in iOS14 instead of our custom picker. -
   Dealing with the photo permission model introduced in iOS14 where user can grant
   access just to specific photo assets or albums

   https://github.com/owncloud/ios-app/issues/851

* Change - Corporate Color + UI Refinements: [#860](https://github.com/owncloud/ios-app/issues/860)

   The corporate color of the UI themes was updated and furthermore some colors was
   adopted for a better contrast. This PR includes also some refinements for some
   UI elements.

   https://github.com/owncloud/ios-app/issues/860

* Change - Improved Right-to-Left Language UI-Design: [#861](https://github.com/owncloud/ios-app/issues/861)

   Fixed missing views, which missed Right-to-Left language support.

   https://github.com/owncloud/ios-app/issues/861

* Change - Enforce User ID when updating token-based bookmarks: [#869](https://github.com/owncloud/ios-app/pull/869)

   This PR requires the user ID to remain the same when updating token-based
   bookmarks. If the user logs in as a user other than the one with which the
   bookmark was originally created, an error will be presented.

   https://github.com/owncloud/ios-app/pull/869

* Change - TLS certificate comparison: [#872](https://github.com/owncloud/ios-app/pull/872)

   When logging into an account and experiencing a different certificate that does
   not fulfill the rules for automatic acceptance as replacement, the issue it
   brings up now shows the differences between the two certificates to allow an
   informed decision by the user.

   https://github.com/owncloud/ios-app/pull/872

* Change - New Issue view / presentation: [#874](https://github.com/owncloud/ios-app/pull/874)

   As fixing an iPad layout issue in the old issues view proved too cumbersome,
   I've replaced the entire implementation with a new issue view, based on code
   already there and in use for cards and tables.

   https://github.com/owncloud/ios-app/pull/874

* Change - Automated Calens Changelog Creation: [#879](https://github.com/owncloud/ios-app/pull/879)

   This PR uses GitHub Actions to automatically generate a changelog file with
   Calens and commits the new CHANGELOG.md into the current branch.

   https://github.com/owncloud/ios-app/pull/879

* Change - MDM Enhancements: [#4104](https://github.com/owncloud/enterprise/issues/4104)

   - Passcode lock enforcement via class setting. User can be forced to set-up a
   passcode when he first starts the app - Auto-generated MDM documentation

   https://github.com/owncloud/enterprise/issues/4104

# Changelog for 11.4.5 versions and below
## Release version 11.4.5 (January 2021)

- Fix: Crash in Detail View (#855)
- Fix: Upload Improvements (PR #857)

## Release version 11.4.4 (End-November 2020)

- Fix: iPad on iOS 12 (#4293)
- Fix: Improvements on Apple Silicon macOS

## Release version 11.4.3 (Mid-November 2020)

- Fix: iOS 14 UI Adaptions (#834)

## Release version 11.4.2 (November 2020)

- Support for new Display Sizes
- Favorites in Directory Picker (#814)
- Rename Filename in Scan View (#822)
- Fix: Save Attachments from Mail.app (#816)
- Fix: Authentication Error in FileProvider (#808)
- Fix: New Folder in FileProvider (#827)

## Release version 11.4.1 (September 2020)

- Image Metadata (#679)
- Pro Photo Upload (#685, #688)
- Fix: Media Upload Path (#784)
- Fix: File List (#786)
- Fix: Markup (#783)
- Fix: Shortcuts (#785)
- Fix: Share Sheet (#782)
- Fix: Multiple Selection (#735)
- Fix: File Provider (#747)
- Fix: General Improvements (#790, #792, #793)
- Fix: Create Public Link (#803)

## Release version 11.4 (August 2020)

- Branding Support (#2, #120)
- Migration (#270)
- Cellular Options (PR #709)
- Share Sheet (#539)
- Camera Access (#615)
- Better Issue Handling (#362, #505, #513, #585, SDK: #63)
- Folders on top (#431)
- Contextual Menu (#717)
- Multitouch gestures (#725)
- Inline Authentication (PR #682)
- Image Upload: Change file name (PR #714)
- App Version Information (#740)
- Improved Media Upload (#647)
- Media Streaming (#766)
- Public Link Creation (#671)
- Diagnostics (PR #762)
- Item Counter (PR #771)
- Universal Links / Deep Linking (PR #609)
- Shortcuts: Get File Info
- Fix: Avoid duplicate photo upload (PR #714)
- Fix: Markup (#729, 698)
- Fix: Audio Playback (#683)
- Fix: Serveral UI Improvements (PR #654, #264)
- Fix: File Provider (#754, …)
- Fix: Quick Access (#745)
- Fix: Sort by Type (#670)

## Release version 1.3.2 (April 2020)

- iPad: Mouse and Trackpad support (#655)
- Fix: Shortcut - Save Action (#651)
- Fix: Keep open files up-to-date (#630)

## Release version 1.3.1 (March 2020)

- Fix: Shortcut - Save Action (#622)
- Fix: Markup Documents (#617, #618)
- Fix: Offline Usage (#3828)
- Fix: Available Offline (PR #616)
- Fix: Permissions (#623)

## Release version 1.3.0 (February 2020)

- Document Scanner on iOS 13 (PR #494)
- Markup Documents on iOS 13 (#541)
- Shortcut Support on iOS 13 (#463)
- New Quick Access Collections (PR #600)
- Cleaner File List Layout (PR #594)
- Added Sort Bar in Directory Picker (#590)
- Fix: Blank File List on UI restoration (#601)
- Fix: Share Sheet on iPad for log files (#606)

## Release version 1.2.1 (January 2020)

- Fix: Passcode Lock Screen on iOS 13 (#582)

## Release version 1.2.0 (December 2019)

- Multiple Window Support (iPadOS) (#488)
- Keyboard Commands (iPadOS) (#282)
- Media Player Improvements (#59, #374)
- Better File Previews (#481)
- Arabic Language Support
- Fix: Sort alphabetically (PR #546)
- Fix: Share Sheet on iPad (#568)
- Fix: FileProvider File Type Issue (#557)
- Fix: FileProvider Offline Browsing (PR #547)
- Fix: FileProvider Saving from Microsoft Word (PR #574)
- Fix: Photo Upload (#504)

## Release version 1.1.2 (October 2019)

- Fix for long delays before starting a request on iOS 13.1 (PR #531)

## Release version 1.1.1 (October 2019)

- Dark mode support (PR #489)
- iOS 13 support (#502)
- Background media playback fixed (PR #522)
- Displaying long file name improved (#516)
- Fixed naming of uploaded edited photos (#520)
- Fixed crash in File Provider (#502)
- UI fixes (#511, #502)

## Release version 1.1.0 (September 2019)

- Available Offline Support (#134, #135)
- Background Sync Support (#386)
- Background Image Upload (#116)
- Import Files from Share Sheet (#76)
- Added "Create Folder" Action in Directory Picker (#443)
- Added Change Sort Order for all Sort Methods (#470)
- Added Index Bar in File list (#413)
- Image Gallery improvements (#322)
- UI improvements for the Navigation Bar (#477)
- Added Activity Indicator for deleting Local Copies (#393)
- Sharing fixes (#439, #415)
- Fixed min length for searching sharing users (#454)

## Release version 1.0.4 (August 2019)

- Authentication improvements (PR #459)
- Fixed background crash (PR #462)
- Log file improvements (#444)

## TestFlight Build 129 (July 2019)

- Import files from Share Sheet (#76)
- Create Folder in Directory Picker (#443)

## TestFlight Build 126 (July 2019)

- Native Media Player, with support for streaming (#395)
- Name Conflict Detection (#377)
- Activity Indicator for deleting offline copies (#393)
- Improved Log File (#446)
- Image Gallery improvement (#322)
- Error handling for corrupted files (#357)

## Release version 1.0.3 (July 2019)

- Add support for local user names with @ inside in sharing (PR #453)

## Release version 1.0.2 (July 2019)

- Favorites crash fixed (#423)
- Account Auto-Connect
- Add support for server setting version.hide (#426)
- OAuth2 improvements (#293)

## Release version 1.0.1 (June 2019)
- Passcode lock for iOS Files.app
- Access log files after log session ended
- Translation fixed
- Sharing bug fixed
- Fixed bug when creating a new folder

## TestFlight Build 123 (June 2019)
- Finally: Sharing !! (#275, #292, #351, #358)
- Option to convert HEIF/HEVC to JPEG/MP4 before upload (#363)
- Option to show/hide hidden files in the file list (#390)
- Debugging: log rotation (#382)
- Clear cached local files (#376)

## TestFlight Build 119 (May 2019)
- Drag and drop between apps (iPad Split View) (#48)
- Drag directly to file actions (#250)
- Multi-select: more file actions (#250)
- Swipe to next image (#277)
- Display quota (#337)
- Navigation to any parent folder (#354)

## TestFlight Build 111 (March 2019)
- Upload multiple images and videos in the app (Select all!!!) (#173 )
- "Open in…" with offline files (#227)
- Basic appconfig.org implementation (#272)

## TestFlight Build 103 (February 2019)
- Multi-select files/folders for move and delete (#234)
- Copy file/folder to another location (#207)
- Accessibility improvements (#239)
- Multi Language: cs_CZ, de, de_DE, en_GB, ko, mk, nb_NO, nn_NO, pt_BR, pt_PT, ru, sq, th_TH, zh_CN (#231)

## TestFlight Build 85 (November 2018)
- Upload (single) images and (multiple) files in the app (#146)
- Open in another app (#132)

## TestFlight Build 83 (November 2018)
- PDF viewer with search and TOC (#138)

## TestFlight Build 79 (November 2018)
- iOS Files app integration (#67)
  - Upload to Files app
  - Download in Files app
  - Edit and save files via Files app
  - Move, rename, delete in Files app
- File size and dates in file list (#117)
- Settings > Logging

## TestFlight Build 73 (October 2018)
- Menu for file/folder info and actions (#106)
- Move of individual files/folders from menu (#110)
- Move multiple files/folders with drag and drop (#110)
- Basic file preview (#114)

## TestFlight Build Build 54 (August 2018)
- Touch ID and Face ID (#54)
- File/folder deletion (#91)
- File/folder rename (#102)
- Filtering/search the current folder (#64)

## TestFlight Build 34 (June 2018)
* Sort options for files and folders (#55)
* Passcode lock with delay option and brute force (activate in "Settings", no Touch ID and Face ID yet) (#34)

## TestFlight Build 31 (May 2018)
* Account creation with OAuth 2.0 and basic auth
* Edit, re-order and delete accounts (#38)
* Inspect SSL-certificates
* Folder navigation (online and offline)
* Thumbnails in file view (#32)
* Different themes (click "Help" on bottom left)
