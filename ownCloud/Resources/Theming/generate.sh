#!/bin/sh

# PREREQUISITE
# Create symlink
# ln -s SYNCDIR\ Config\ Data/5500Z000003poZfQAI/ios/current ~/Developer/github.com/owncloud/ios-app/ownCloud/Resources/Theming/theme.damken

current_dir=$(pwd)
theming_dir="/ownCloud/Resources/Theming"
theme=$1

git submodule init
git submodule update

rename 's/current./theme./' $current_dir$theming_dir/*.*
mv $current_dir$theming_dir/theme.$theme $current_dir$theming_dir/current.$theme

cp $current_dir$theming_dir/current*/*.png $current_dir$theming_dir/
cp $current_dir$theming_dir/current*/*.json $current_dir$theming_dir/Branding.json

fastlane generate_appicon

gomplate --file ./tools/gomplate/Branding.plist.tmpl \
--context config=$current_dir$theming_dir/Branding.json \
--out $current_dir$theming_dir/Branding.plist