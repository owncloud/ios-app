If you want to start help developing ownCloud please follow the [contribution guidelines][0] and observe these instructions:


NOTE: To compile the code you need Xcode 9, iOS11, cocoa pods and swiftlint.
  
### 1. Fork and download ios-app/master repository:

* Navigate to https://github.com/owncloud/ios-app, click fork.
* Clone your new repo:```git clone git@github.com:YOURGITHUBNAME/ios-app.git```
* Move to the project folder with ```cd ios-app```
* Checkout remote develop branch:```git checkout -b master remotes/origin/master```
* Pull changes from your develop branch: ```git pull origin master```
* Make official ownCloud repo known as upstream: ```git remote add upstream git@github.com:owncloud/ios-app.git```
* Make sure to get the latest changes from official ios-issues/master branch: ```git pull upstream master```

### 2. Set up in your local

## [Cocoa pods][cocoapods]

## [Swiftlint][swiftlint]

## [EarlGrey][earlGrey]

[cocoapods]:https://cocoapods.org/
[swiftlint]:https://github.com/realm/SwiftLint/blob/master/README.md
[earlGrey]:https://github.com/google/EarlGrey/blob/master/docs/install-and-run.md#cocoapods-installation


### 3. Add the ownCloud iOS SDK:

NOTE: This will connect with our ownCloud iOS Library repository at ```https://github.com/owncloud/ios-sdk```.

* Inside the folder ios:
  - Init the library submodule: "git submodule init"
  - Update the library submodule: "git submodule update"

### 4. Create your own certificates

NOTE: You must use the same "extension" on the certificates of the extensions (ownCloudExtApp, ownCloudExtAppFileProvider, OC-Share-Sheet)

* Login at https://developer.apple.com/ as developer and there to to the Certificates section.
* Create a Development Certificate for you (probably you got it one now)
* Create an App Id for the main app. Ex: com.mywebpage.owncloud.ios
* Create an AppGroup and add it too all the App Id. Must have the App Id than the main app but with the group. Ex: group.com.mywebpage.owncloud.ios
* Add the UDID of your device on the Devices section.
* Create 4 Development Profiles. One for each App Id.

### 5. Create pull request:
  
NOTE: You must sign the [Contributor Agreement][1] or contribute your code under the [MIT license][2] before your changes can be accepted! See the [iOS license exception][3] for testing the ownCloud iOS app on Apple hardware.

* Remove your own App Id from the project and set again the ownCloud ones:
  - Main app: com.owncloud.ios-app

* Commit your changes locally: "git commit -a"
* Push your changes to your Github repo: "git push"
* Browse to https://github.com/YOURGITHUBNAME/ios/pulls and issue pull request
* Click "Edit" and set "base:master"
* Again, click "Edit" and set "compare:master"
* Enter description and send pull request.

### 6. Create another pull request:

To make sure your new pull request does not contain commits which are already contained in previous PRs, create a new branch which is a clone of upstream/master.

* ```git fetch upstream```
* ```git checkout -b my_new_master_branch upstream/master```
* If you want to rename that branch later: ```git checkout -b my_new_master_branch_with_new_name```
* Push branch to server: ```git push -u origin name_of_local_master_branch```
* Use Github to issue PR

## Translations
Please submit translations via [Transifex][transifex].

[transifex]: https://www.transifex.com/projects/p/owncloud/


[0]: https://github.com/owncloud/ios/CONTRIBUTING.md
[1]: https://owncloud.org/about/contributor-agreement/
[2]: http://opensource.org/licenses/MIT
[3]: https://owncloud.org/contribute/iOS-license-exception/
