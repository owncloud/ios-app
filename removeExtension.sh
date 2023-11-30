#! /bin/bash

 # Copyright (C) 2023, ownCloud GmbH.
 #
 # This code is covered by the GNU Public License Version 3.
 #
 # For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 # You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 
 VERSION="1.0.0"
 
 #Define output formats
 BOLD="$(tput bold)"
 WARN="$(tput setaf 1)"
 SUCCESS="$(tput setaf 2)"
 INFO="$(tput setaf 3)"
 NC="$(tput sgr0)" # No Color
 
 usage()
 {
   echo "Usage:  $0 \"Path to IPA\" \"Target Name\""
   echo "Version: ${VERSION}"
   echo ""
   exit 1
 }

 
 #Check if all required parameters exist
 if [ $# -lt 2 ]; then
   usage
 fi
 
 echo
 echo "${BOLD}${SUCCESS}Remove Extension Tool${NC}"
 echo "Version ${VERSION}"
 echo
 
 # Extract the file name from the path
IPA_FILE=$1
 APPTEMP="apptemp"
 APPPATH="$APPTEMP/ownCloud.app"

 
 # Delete previous temporal app folder if exist
 if [ -d  "$APPTEMP" ]; then
	 rm -rf "$APPTEMP"
 fi
 
 # Create temp directory
 mkdir $APPTEMP
 
 export PATH=$PATH:/usr/libexec
 
 # Unzip ipa
 echo "${SUCCESS}Unzipping ipa…${NC}"
 echo ""
 
 unzip -q "$IPA_FILE" -d "$APPTEMP" || { echo "${WARN}Failed to unzip ipa file${NC}"; exit 1; }
 
 if [ ! -d "$APPPATH" ]; then
	APPPATH="$APPTEMP/Payload/ownCloud.app"
 fi
 
EXTENSIONPATH="$APPPATH/PlugIns/$2.appex"
 
echo "${SUCCESS}Remove $EXTENSIONPATH ${NC}"

# Remove the extension
rm -rf "$EXTENSIONPATH"

# Delete input IPA file
rm -rf "$IPA_FILE"
 
# Generate new Payload
echo ""
echo "${SUCCESS}Packing new ipa…${NC}"
pushd "$APPTEMP"
zip -q -r "../$IPA_FILE" *
popd
 
# Delete previous temporal app folder if exist
if [ -d  "$APPTEMP" ]; then
	rm -rf "$APPTEMP"
fi