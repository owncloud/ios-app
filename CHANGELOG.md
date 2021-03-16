Changelog for ownCloud iOS Client [unreleased] (UNRELEASED)
=======================================
The following sections list the changes in ownCloud iOS Client unreleased relevant to
ownCloud admins and users.

[unreleased]: https://github.com/owncloud/client/compare/v11.5.2...master

Summary
-------

* Bugfix - Swiping PDF thumbnail view on the iPhone: [#918](https://github.com/owncloud/ios-app/issues/918)
* Change - French Localization: [#4450](https://github.com/owncloud/enterprise/issues/4450)
* Change - Presentation Mode: [#704](https://github.com/owncloud/ios-app/issues/704)

Details
-------

* Bugfix - Swiping PDF thumbnail view on the iPhone: [#918](https://github.com/owncloud/ios-app/issues/918)

   Prevent page container scrolling, when try to scroll inside the pdf thumbnail view on the
   iPhone

   https://github.com/owncloud/ios-app/issues/918

* Change - French Localization: [#4450](https://github.com/owncloud/enterprise/issues/4450)

   Added french localization.

   https://github.com/owncloud/enterprise/issues/4450

* Change - Presentation Mode: [#704](https://github.com/owncloud/ios-app/issues/704)

   Added an action in detail view menu which enables presentation mode. Presentation mode
   prevents the display from sleep mode as long as the detail view is closed. Furthermore the
   navigation bar will be hidden.

   https://github.com/owncloud/ios-app/issues/704

Changelog for ownCloud iOS Client [11.5.2] (2020-03-03)
=======================================
The following sections list the changes in ownCloud iOS Client 11.5.2 relevant to
ownCloud admins and users.

[11.5.2]: https://github.com/owncloud/client/compare/v11.5.1...v11.5.2

Summary
-------

* Bugfix - Accessing hyperlinks in PDF documents: [#4432](https://github.com/owncloud/enterprise/issues/4432)
* Bugfix - PDF thumbnail view position on the iPad: [#905](https://github.com/owncloud/ios-app/pull/905)
* Bugfix - Misplaced Collapsible Progress Bar in detail view: [#906](https://github.com/owncloud/ios-app/issues/906)

Details
-------

* Bugfix - Accessing hyperlinks in PDF documents: [#4432](https://github.com/owncloud/enterprise/issues/4432)

   Tap on hyperlinks in PDF documents opens the link.

   https://github.com/owncloud/enterprise/issues/4432

* Bugfix - PDF thumbnail view position on the iPad: [#905](https://github.com/owncloud/ios-app/pull/905)

   Fixed the position of the PDF thumbnail view on the iPad from the bottom to the right position to
   get more visible PDF content and to prevent enabling the iOS app switcher when scrolling throw
   the thumbnail view.

   https://github.com/owncloud/ios-app/pull/905

* Bugfix - Misplaced Collapsible Progress Bar in detail view: [#906](https://github.com/owncloud/ios-app/issues/906)

   Hide the Collapsible Progress Bar in detail view and fixed position in file list.

   https://github.com/owncloud/ios-app/issues/906

Changelog for ownCloud iOS Client [11.5.1] (2020-02-17)
=======================================
The following sections list the changes in ownCloud iOS Client 11.5.1 relevant to
ownCloud admins and users.

[11.5.1]: https://github.com/owncloud/client/compare/v11.5.0...v11.5.1

Summary
-------

* Bugfix - Fix Crash on iOS 12 devices: [#896](https://github.com/owncloud/ios-app/pull/896)

Details
-------

* Bugfix - Fix Crash on iOS 12 devices: [#896](https://github.com/owncloud/ios-app/pull/896)

   Fixed a crash on startup, when iOS 12 is installed on the device.

   https://github.com/owncloud/ios-app/pull/896

Changelog for ownCloud iOS Client [11.5.0] (2020-02-10)
=======================================
The following sections list the changes in ownCloud iOS Client 11.5.0 relevant to
ownCloud admins and users.



Summary
-------

* Bugfix - Added paragraph on top of Acknowledgements page: [#4284](https://github.com/owncloud/enterprise/issues/4284)
* Bugfix - Fixed Branded UI on iPad: [#4367](https://github.com/owncloud/enterprise/issues/4367)
* Bugfix - Improved AppStore Review Request Time: [#845](https://github.com/owncloud/ios-app/pull/845)
* Bugfix - Changed wording in documentation: [#867](https://github.com/owncloud/ios-app/pull/867)
* Bugfix - Fix bookmark name editing: [#877](https://github.com/owncloud/ios-app/pull/877)
* Bugfix - Media Player Behaviour: [#884](https://github.com/owncloud/ios-app/pull/884)
* Change - MDM Enhancements: [#4104](https://github.com/owncloud/enterprise/issues/4104)
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

Details
-------

* Bugfix - Added paragraph on top of Acknowledgements page: [#4284](https://github.com/owncloud/enterprise/issues/4284)

   - adds a paragraph on top of the Acknowledgements to provide additional context - adds
   PLCrashReporter license to acknowledgements

   https://github.com/owncloud/enterprise/issues/4284

* Bugfix - Fixed Branded UI on iPad: [#4367](https://github.com/owncloud/enterprise/issues/4367)

   - UI fix for branded login on the iPad - Fill color for branded button was not used

   https://github.com/owncloud/enterprise/issues/4367
   https://github.com/owncloud/enterprise/issues/4366

* Bugfix - Improved AppStore Review Request Time: [#845](https://github.com/owncloud/ios-app/pull/845)

   Changed request time for In-App review and fixed storing the first launch date

   https://github.com/owncloud/ios-app/pull/845

* Bugfix - Changed wording in documentation: [#867](https://github.com/owncloud/ios-app/pull/867)

   Changed wording so it no longer suggests username is editable

   https://github.com/owncloud/ios-app/pull/867

* Bugfix - Fix bookmark name editing: [#877](https://github.com/owncloud/ios-app/pull/877)

   When editing bookmarks:

   - if a name was set, it wasn't shown in the edit interface - bookmark name edits/additions would
   get lost - bookmark name edits would not be presented in the list unless scrolling out of view and
   back in

   https://github.com/owncloud/ios-app/pull/877

* Bugfix - Media Player Behaviour: [#884](https://github.com/owncloud/ios-app/pull/884)

   Fix for an issue when playing multiple items in the same directory. If e.g. image item is the next
   one, multi media playback would stop.

   https://github.com/owncloud/ios-app/pull/884

* Change - MDM Enhancements: [#4104](https://github.com/owncloud/enterprise/issues/4104)

   - Passcode lock enforcement via class setting. User can be forced to set-up a passcode when he
   first starts the app - Auto-generated MDM documentation

   https://github.com/owncloud/enterprise/issues/4104

* Change - Full Screen PDF View: [#428](https://github.com/owncloud/ios-app/issues/428)

   - A PDF file can be opened in fullscreen view and hides unnecessary UI elements. (Tap to trigger
   full screen view) - Thumbnails positioned based on vertical size class after rotating the
   device to give the displayed document more screen real estate.

   https://github.com/owncloud/ios-app/issues/428

* Change - Unified Branding with MDM support: [#697](https://github.com/owncloud/ios-app/issues/697)

   Refactored Branding, introducing a new Branding class, unifying branding support with class
   settings while offering support for the legacy format and laying the ground for retrieving
   branding assets from a remote server.

   https://github.com/owncloud/ios-app/issues/697
   https://github.com/owncloud/ios-app/issues/792

* Change - Class Settings Metadata Support: [#831](https://github.com/owncloud/ios-app/issues/831)

   Support for class settings metadata.

   https://github.com/owncloud/ios-app/issues/831

* Change - Video upload improvements: [#847](https://github.com/owncloud/ios-app/issues/847)

   - Added ability to upload slo-mo videos etc - Added option to allow uploading original videos

   https://github.com/owncloud/ios-app/issues/847

* Change - Enhanced drag & drop support: [#850](https://github.com/owncloud/ios-app/pull/850)

   Fix drag and drop and improve support to run the iOS app on M1 Macs:

   - add drag-out support for files that are not locally available yet - improve drag-in support
   for files, picking the best available representation that can be retrieved as data - support
   for drag & drop in the log file browser

   https://github.com/owncloud/ios-app/pull/850

* Change - New photo picker / permissions model for iOS 14: [#851](https://github.com/owncloud/ios-app/issues/851)

   - Using new PHPhotoPicker introduced in iOS14 instead of our custom picker. - Dealing with the
   photo permission model introduced in iOS14 where user can grant access just to specific photo
   assets or albums

   https://github.com/owncloud/ios-app/issues/851

* Change - Corporate Color + UI Refinements: [#860](https://github.com/owncloud/ios-app/issues/860)

   The corporate color of the UI themes was updated and furthermore some colors was adopted for a
   better contrast. This PR includes also some refinements for some UI elements.

   https://github.com/owncloud/ios-app/issues/860

* Change - Improved Right-to-Left Language UI-Design: [#861](https://github.com/owncloud/ios-app/issues/861)

   Fixed missing views, which missed Right-to-Left language support.

   https://github.com/owncloud/ios-app/issues/861

* Change - Enforce User ID when updating token-based bookmarks: [#869](https://github.com/owncloud/ios-app/pull/869)

   This PR requires the user ID to remain the same when updating token-based bookmarks. If the user
   logs in as a user other than the one with which the bookmark was originally created, an error will
   be presented.

   https://github.com/owncloud/ios-app/pull/869

* Change - TLS certificate comparison: [#872](https://github.com/owncloud/ios-app/pull/872)

   When logging into an account and experiencing a different certificate that does not fulfill
   the rules for automatic acceptance as replacement, the issue it brings up now shows the
   differences between the two certificates to allow an informed decision by the user.

   https://github.com/owncloud/ios-app/pull/872

* Change - New Issue view / presentation: [#874](https://github.com/owncloud/ios-app/pull/874)

   As fixing an iPad layout issue in the old issues view proved too cumbersome, I've replaced the
   entire implementation with a new issue view, based on code already there and in use for cards and
   tables.

   https://github.com/owncloud/ios-app/pull/874

* Change - Automated Calens Changelog Creation: [#879](https://github.com/owncloud/ios-app/pull/879)

   This PR uses GitHub Actions to automatically generate a changelog file with Calens and commits
   the new CHANGELOG.md into the current branch.

   https://github.com/owncloud/ios-app/pull/879

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
