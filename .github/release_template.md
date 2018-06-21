<!--
This is the template to release a new version on the App Store
-->

Release a new version
## TASKS:

Git & Code

- [ ] [GIT] Create branch `release/[major].[minor].[patch]` (freeze the code)
- [ ] [DEV] Update version number `[major].[minor].[patch]`
- [ ] [DIS] Update [changelog](https://github.com/owncloud/ios-app/blob/master/CHANGELOG.md)
- [ ] [QA] Design Test plan
- [ ] [QA] Regression Test plan
- [ ] [DOC] Update user manual with the new functionalities

App Store

- [ ] [DIS] iTunes Connect: Create a new version following the `[major].[minor].[patch]`
- [ ] [DIS] iTunes Connect: Update screenshots if needed
- [ ] [DIS] Upload the binary to the App Store
- [ ] [DIS] iTunes Connect: When release (manually, automatically, automatically not early than date)
- [ ] [DIS] iTunes Connect: How to releae (immediately to all the users o 7-day period phased release)
- [ ] [DIS] iTunes Connect: Reset iOS Summary Rating (Keep existing or reset the rating)
- [ ] [DIS] iTunes Connect: Update changelogs
- [ ] [DIS] iTunes Connect: Submit for review

Git

- [ ] [GIT] Merge branch `release/[major].[minor].[patch]` in master
- [ ] [GIT] Create tag and sign it `[major].[minor].[patch]`
- [ ] [GIT] Add the new release on [GitHub ios-app](https://github.com/owncloud/ios-app/releases)

If it is required to update third party:

- [ ] [DIS] Update THIRD_PARTY.txt

If it is required to update the iOS-SDK version:

- [ ] [GIT] Create branch library `release/[major].[minor].[patch]`(freeze the code) 
- [ ] [mail] inform john@owncloud.com and emil@owncloud.com about the new release.
- [ ] [DIS] Update README.md (version number, third party, supported versions of iOS, Xcode)
- [ ] [DIS] Update [changelog](https://github.com/owncloud/ios-sdk/blob/master/CHANGELOG.md)
- [ ] [GIT] Merge branch `release/[major].[minor].[patch]` in `master`
- [ ] [GIT] Create tag and sign it `[major].[minor].[patch]`
- [ ] [GIT] Add the new release on [GitHub ios-sdk](https://github.com/owncloud/ios-sdk/releases)


## BUGS & IMPROVEMENTS:

