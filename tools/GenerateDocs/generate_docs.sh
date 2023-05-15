#!/bin/bash

# Run test to update CONFIGURATION.json
xcodebuild test \
-project ../../ownCloud.xcodeproj \
-scheme ownCloud \
-destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
-only-testing ownCloudTests/MetadataDocumentationTests/testUpdateConfigurationJSONFromMetadata

# Run gomplate to generate the adoc
gomplate -f templates/configuration.adoc.tmpl --context config=../../doc/CONFIGURATION.json -o ../../doc/configuration.adoc
