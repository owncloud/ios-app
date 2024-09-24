#!/bin/bash

# Run test to update CONFIGURATION.json
xcodebuild test \
-project ../../ownCloud.xcodeproj \
-scheme ownCloud \
-destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
-only-testing ownCloudTests/MetadataDocumentationTests/testUpdateConfigurationJSONFromMetadata

# Make temporary copy
cp ../../doc/CONFIGURATION.json .

# Run gomplate to generate the adoc
gomplate -f templates/configuration.adoc.tmpl --context config=CONFIGURATION.json -o configuration.adoc

# Copy result back and remove temporary copy
rm CONFIGURATION.json
cp configuration.adoc ../../doc/
