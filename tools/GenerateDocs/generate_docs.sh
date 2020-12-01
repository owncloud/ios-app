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
gomplate -f templates/ios_mdm_tables.adoc.tmpl --context config=../../doc/CONFIGURATION.json -o ../../docs/modules/ROOT/pages/ios_mdm_tables.adoc
