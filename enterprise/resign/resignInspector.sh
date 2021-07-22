#! /bin/bash

 # Copyright (C) 2021, ownCloud GmbH.
 #
 # This code is covered by the GNU Public License Version 3.
 #
 # For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 # You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 
 VERSION="1.0.0"
 
 #Define output formats
 BOLD="$(tput bold)"
 UNDERLINED="$(tput smul)"
 NOTUNDERLINED="$(tput rmul)"
 WARN="$(tput setaf 1)"
 SUCCESS="$(tput setaf 2)"
 INFO="$(tput setaf 3)"
 NC="$(tput sgr0)" # No Color
 
 usage()
 {
   echo "Usage:  $0 \"Path to IPA\""
   echo "Version: ${VERSION}"
   echo ""
   exit 1
 }
 
 countDots()
 {
	echo "$1" | grep -o "\." | grep -c "\."
 }
 
 #Check if all required parameters exist
 if [ $# -lt 1 ]; then
   usage
 fi
 
 echo
 echo "${BOLD}${SUCCESS}ownCloud iOS-App Resigning Inspector${NC}"
 echo "Version ${VERSION}"
 echo
 echo "${SUCCESS}Starting IPA inspection…${NC}"
 echo ""
 
 UNSIGNED_IPA=$1
 APPTEMP="apptemp"
 APPPATH="$APPTEMP/ownCloud.app"
 
 if [ ! -f "$UNSIGNED_IPA" ]; then
 echo "${WARN}Error: can't find $UNSIGNED_IPA on the given path${NC}"
 exit 1
fi
 
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
 
 unzip -q "$UNSIGNED_IPA" -d "$APPTEMP" || { echo "${WARN}Failed to unzip ipa file${NC}"; exit 1; }
 
 if [ ! -d "$APPPATH" ]; then
	APPPATH="$APPTEMP/Payload/ownCloud.app"
 fi
 
  declare -a LOCATIONS=(      "$APPPATH/"   "$APPPATH/PlugIns/ownCloud File Provider.appex"  "$APPPATH/PlugIns/ownCloud File Provider UI.appex"  "$APPPATH/PlugIns/ownCloud Intents.appex"  "$APPPATH/PlugIns/ownCloud Share Extension.appex" );
 
  echo "${SUCCESS}Checking entitlements…${NC}"
  echo ""
 for a in "${LOCATIONS[@]}"
 do
 	if [ ! -d "$a" ]; then
 		echo "${WARN}Error: can't find $a in the current directory${NC}"
 		exit 1
	fi
	
	echo "${SUCCESS}$a${NC}"
	echo ""
	codesign -d --ent :- "$a"
	echo ""
	
	PLISTVALUE=`PlistBuddy -c "print CFBundleIdentifier " "$a/Info.plist"`
	if [[ `countDots "$PLISTVALUE"` -le "2" ]]; then
		echo "${WARN}Value may be wrong for CFBundleIdentifier: $PLISTVALUE${NC}"
	else 
		echo "CFBundleIdentifier: ${SUCCESS}$PLISTVALUE${NC}"
	fi
	PLISTVALUE=`PlistBuddy -c "print OCAppGroupIdentifier " "$a/Info.plist"`
	if [[ `countDots "$PLISTVALUE"` -le "2" ]]; then
		echo "${WARN}Value may be wrong for OCAppGroupIdentifier: $PLISTVALUE${NC}"
	else 
		echo "OCAppGroupIdentifier: ${SUCCESS}$PLISTVALUE${NC}"
	fi
	PLISTVALUE=`PlistBuddy -c "print OCKeychainAccessGroupIdentifier " "$a/Info.plist"`
	if [[ `countDots "$PLISTVALUE"` -le "2" ]]; then
		echo "${WARN}Value may be wrong for OCKeychainAccessGroupIdentifier: $PLISTVALUE${NC}"
	else 
		echo "OCKeychainAccessGroupIdentifier: ${SUCCESS}$PLISTVALUE${NC}"
	fi
	PLISTVALUE=`PlistBuddy -c "print OCAppIdentifierPrefix " "$a/Info.plist"`
	if [[ `countDots "$PLISTVALUE"` -le "0" ]]; then
		echo "${WARN}Value may be wrong for OCAppIdentifierPrefix: $PLISTVALUE${NC}"
	else 
		echo "OCAppIdentifierPrefix: ${SUCCESS}$PLISTVALUE${NC}"
	fi
	if [[ "$a" =~ ^(ownCloud File Provider.appex)$ ]]; then
		PLISTVALUE=`PlistBuddy -c "print NSExtension:NSExtensionFileProviderDocumentGroup " "$a/Info.plist"`
		if [[ `countDots "$PLISTVALUE"` -le "2" ]]; then
			echo "${WARN}Value may be wrong for NSExtensionFileProviderDocumentGroup: $PLISTVALUE${NC}"
		else 
			echo "NSExtension:NSExtensionFileProviderDocumentGroup: ${SUCCESS}$PLISTVALUE${NC}"
		fi
	fi
	echo ""
		
 done
 
 # Delete previous temporal app folder if exist
  if [ -d  "$APPTEMP" ]; then
	rm -rf "$APPTEMP"
  fi