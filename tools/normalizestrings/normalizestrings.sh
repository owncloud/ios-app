#!/bin/bash

# Build ocstringstool
cd ../../ios-sdk/tools/ocstringstool/
./build_tool.sh
cd ../normalizestrings
cd ../../../tools/normalizestrings/
mv ../../ios-sdk/tools/ocstringstool/tool ./ocstringstool
chmod u+x ./ocstringstool

# Perform normalization
echo "Normalizing…"
./ocstringstool normalize ../../ownCloud/Resources/

# Remove ocstringstool build
rm ./ocstringstool

echo "Done."

