<!--
This is the template to release a new version on the App Store
-->

Release a new version
## TASKS:

### Git & Code

- [ ] [GIT] Create branch `release/[major].[minor].[patch]` (freeze the code)
- [ ] [DEV] Update `APP_SHORT_VERSION` `[major].[minor].[patch]` in [ownCloud.xcodeproj/project.pbxproj](https://github.com/owncloud/ios-app/blob/master/ownCloud.xcodeproj/project.pbxproj)
- [ ] [TRFX] Update translations from transifex branch.
- [ ] [DIS] Update [changelog](https://github.com/owncloud/ios-app/blob/master/CHANGELOG.md)
- [ ] [DEV] Update In-App Release Notes (changelog) in ownCloud/Release Notes/ReleaseNotes.plist
- [ ] [QA] Design Test plan
- [ ] [QA] Regression Test plan
- [ ] [DOC] Update user manual with the new functionalities
- [ ] [DOC] Update owncloud.org/download version numbers (notify #wordpress)
- [ ] [GIT] Merge branch `release/[major].[minor].[patch]` in master
- [ ] [GIT] Create tag and sign it `[major].[minor].[patch]`
- [ ] [GIT] Add the new release on [GitHub ios-app](https://github.com/owncloud/ios-app/releases)

If it is required to update the iOS-SDK version:

- [ ] [GIT] Create branch library `release/[major].[minor].[patch]`(freeze the code)
- [ ] [mail] inform #marketing about the new release.
- [ ] [DIS] Update README.md (version number, third party, supported versions of iOS, Xcode)
- [ ] [DIS] Update [changelog](https://github.com/owncloud/ios-sdk/blob/master/CHANGELOG.md)
- [ ] [GIT] Merge branch `release/[major].[minor].[patch]` in `master`
- [ ] [GIT] Create tag and sign it `[major].[minor].[patch]`
- [ ] [GIT] Add the new release on [GitHub ios-sdk](https://github.com/owncloud/ios-sdk/releases)

If it is required to update third party:

- [ ] [DIS] Update THIRD_PARTY.txt

## App Store

- [ ] [DIS] App Store Connect: Create a new version following the `[major].[minor].[patch]`
- [ ] [DIS] App Store Connect: Trigger Fastlane screenshots generation and upload
- [ ] [DIS] Upload the binary to the App Store
- [ ] [DIS] App Store Connect: Trigger release (manually)
- [ ] [DIS] App Store Connect: Decide reset of iOS summary rating (Default: keep)
- [ ] [DIS] App Store Connect: Update description if necessary (coordinated with #marketing)
- [ ] [DIS] App Store Connect: Update changelogs
- [ ] [DIS] App Store Connect: Submit for review

## BUGS & IMPROVEMENTS:
