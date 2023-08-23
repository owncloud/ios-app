#!/bin/bash

# Run test to convert the app's Localizable.strings to UTF-8 where needed
xcodebuild test \
-project ../../ownCloud.xcodeproj \
-scheme ownCloud \
-destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
-only-testing ownCloudTests/LocalizationTests/testConvertLocalizableUTF16
