#!/bin/bash

# Update/Install CocoaPods
pod install

# Run test to update CONFIGURATION.json
xcodebuild test \
-workspace ../../ownCloud.xcworkspace \
-scheme ownCloud \
-destination 'platform=iOS Simulator,name=iPhone 8,OS=latest' \
-only-testing ownCloudTests/MetadataDocumentationTests/testUpdateConfigurationJSONFromMetadata

# Run gomplate to generate the adoc
gomplate -f templates/configuration.adoc.tmpl --context config=../../doc/CONFIGURATION.json -o ../../doc/configuration.adoc
