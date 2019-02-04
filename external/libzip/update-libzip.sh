#!/bin/bash

#
#  Created by Felix Schwarz on 26.01.19.
#  Copyright (C) 2019 ownCloud GmbH. All rights reserved.
#

# Clone from GitHub
git clone -b rel-1-5-1 https://github.com/nih-at/libzip.git

# Recreate lib directory
rm -r lib
mkdir lib

# Copy relevant files
cp -a libzip/LICENSE .
cp -a libzip/lib .
cp -a libzip/xcode/zipconf.h lib
cp -a libzip/xcode/config.h lib

# Patch include line
sed -i "" -e 's/\<zipconf\.h\>/\"zipconf\.h\"/g' lib/zip.h

# Clean up
rm -rf libzip
