//
//  ConfidentialManager.m
//  ownCloud
//
//  Created by Matthias Hühne on 09.12.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "ConfidentialManager.h"
#import "OCFileProviderSettings.h"

@implementation ConfidentialManager

+ (void)load
{
	[OCClassSettings.sharedSettings addSource:ConfidentialManager.sharedConfidentialManager];
}

+ (instancetype)sharedConfidentialManager
{
	static dispatch_once_t onceToken;
	static ConfidentialManager *sharedInstance;

	dispatch_once(&onceToken, ^{
		sharedInstance = [ConfidentialManager new];
	});

	return (sharedInstance);
}

#pragma mark - Class settings

+ (OCClassSettingsIdentifier)classSettingsIdentifier
{
	return (OCClassSettingsIdentifierConfidential);
}

- (BOOL)allowScreenshots {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyAllowScreenshots];
	return (value != nil) ? value.boolValue : YES;
}

- (BOOL)markConfidentialViews {
	return ([self showUserEmail] || [self showUserID] || [self showTimestamp] || ([[self customText] length] > 0));
}

- (BOOL)allowOverwriteConfidentialMDMSettings {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings];
	return self.confidentialSettingsEnabled && ((value != nil) ? value.boolValue : NO);
}

- (BOOL)confidentialSettingsEnabled {
	return (!self.allowScreenshots || self.markConfidentialViews);
}

- (CGFloat)textOpacity {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextOpacity];
	return (value != nil) ? (value.intValue / 100.0) : 0.6;
}

- (NSString *)textColor {
	return ([self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextColor]);
}

- (CGFloat)columnSpacing {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextColumnSpacing];
	return (value != nil) ? value.floatValue : 40.0;
}

- (CGFloat)lineSpacing {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextLineSpacing];
	return (value != nil) ? value.floatValue : 40.0;
}

- (BOOL)showUserEmail {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextShowUserEmail];
	return (value != nil) ? value.boolValue : NO;
}

- (BOOL)showUserID {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextShowUserID];
	return (value != nil) ? value.boolValue : NO;
}

- (BOOL)showTimestamp {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextShowTimestamp];
	return (value != nil) ? value.boolValue : NO;
}

- (NSString *)customText {
	return ([self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextCustomText]);
}

- (NSInteger)visibleRedactedCharacters {
	NSNumber *value = [self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialVisibleRedactedCharacters];
	return (value != nil) ? value.integerValue : -1;
}

- (NSArray<OCExtensionIdentifier> *)exemptActions {
	return ([self classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialExemptedActions]);
}

+ (NSArray<OCExtensionIdentifier> *)autoDisallowedActions {
	return (@[
		@"com.owncloud.action.openin",
		@"com.owncloud.action.copy",
		/*
			As of iOS 18.2.1:
			The markup action could not be modified to implement protection mechanisms -
			not even on the CALayer level - without interaction with the system-provided
			view breaking and becoming unusable in different ways. A possible reason for
			this is that the markup feature is delivered by the OS as Remote UI (visible
			as QLRemoteUIHostViewController in the view hierarchy) and that otherwise working
			approaches to "passing through" events are not usable with these.
		*/
		@"com.owncloud.action.markup"
	]);
}

- (NSArray<OCExtensionIdentifier> *)disallowedActions {
	if (self.confidentialSettingsEnabled && !self.allowOverwriteConfidentialMDMSettings) {
		NSMutableArray<NSString *> *disallowedActions = [ConfidentialManager.autoDisallowedActions mutableCopy];
		NSArray<NSString *> *exemptActions;

		if (((exemptActions = self.exemptActions) != nil) && (exemptActions.count > 0)) {
			[disallowedActions removeObjectsInArray:exemptActions];
		}

		return (disallowedActions);
	}
	return (nil);
}

+ (NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	return (nil);
}

+ (OCClassSettingsMetadataCollection)classSettingsMetadata
{
	NSArray<OCExtensionIdentifier> *possibleExemptActionIDs = ConfidentialManager.autoDisallowedActions;
	NSMutableArray<NSDictionary<OCExtensionIdentifier, NSString *> *> *possibleExemptionValues = [NSMutableArray new];

	for (OCExtensionIdentifier actionID in possibleExemptActionIDs) {
		[possibleExemptionValues addObject:@{
			OCClassSettingsMetadataKeyValue : actionID,
			OCClassSettingsMetadataKeyDescription : [NSString stringWithFormat:@"Exempt %@ from list of auto-disallowed actions.", actionID]
		}];
	}

	return (@{
		OCClassSettingsKeyAllowScreenshots : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription	: @"Controls whether screenshots are allowed or not. If not allowed confidential views will be marked as sensitive and are not visible in screenshots.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription	: @"Controls if confidential related MDM settings can be overwritten.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialExemptedActions : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeStringArray,
			OCClassSettingsMetadataKeyDescription	: @"List of actions exempt from auto-disallow of particular actions when enabling confidential protections.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential",
			OCClassSettingsMetadataKeyPossibleValues: possibleExemptionValues
		},
		OCClassSettingsKeyConfidentialTextOpacity : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription	: @"Controls the opacity of the watermark text. Possible values: 0 - 100",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextColumnSpacing : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription	: @"Controls the column spacing of the watermark text in pixel.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextLineSpacing : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription	: @"Controls the line spacing of the watermark text in pixel.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextColor : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription	: @"Controls the color as hex value of the watermark text.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialVisibleRedactedCharacters : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeInteger,
			OCClassSettingsMetadataKeyDescription	: @"Controls the number or visible characters in redacted text. Choose value -1 to do not redact text.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextShowUserEmail : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription	: @"Controls if the user email should be shown as watermark text.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextShowUserID : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription	: @"Controls if the user ID should be shown as watermark text.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextShowTimestamp : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeBoolean,
			OCClassSettingsMetadataKeyDescription	: @"Controls if the current timestamp should be shown as watermark text.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextCustomText : @{
			OCClassSettingsMetadataKeyType		: OCClassSettingsMetadataTypeString,
			OCClassSettingsMetadataKeyDescription	: @"Controls if the given custom text should be shown as watermark text.",
			OCClassSettingsMetadataKeyStatus	: OCClassSettingsKeyStatusAdvanced,
			OCClassSettingsMetadataKeyCategory	: @"Confidential"
		}
	});
}

#pragma mark - Class settings source
- (OCClassSettingsSourceIdentifier)settingsSourceIdentifier
{
	return (OCClassSettingsSourceIdentifierConfidentialManager);
}

- (nullable NSDictionary<OCClassSettingsKey, id> *)settingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	if (!self.allowOverwriteConfidentialMDMSettings && self.confidentialSettingsEnabled) {
		// Action
		if ([identifier isEqual:@"action"]) { // OCClassSettingsIdentifier.action
			// Disallow image interactions (ImageScrollView.imageInteractionsAllowed)
			return (@{
				@"allow-image-interactions" : @(NO) // OCClassSettingsKey.allowImageInteractions
			});
		}

		// File Provider
		if ([identifier isEqual:OCClassSettingsIdentifierFileProvider]) {
			// Disallow File Provider browsing
			return (@{
				OCClassSettingsKeyFileProviderBrowseable : @(NO)
			});
		}

		// Shortcuts
		if ([identifier isEqual:@"shortcuts"]) { // OCClassSettingsIdentifier.shortcuts
			// Disallow shortcuts (IntentSettings.isEnabled)
			return (@{
				@"enabled" : @(NO) // OCClassSettingsKey.shortcutsEnabled
			});
		}
	}

	return (nil);
}

@end

OCClassSettingsSourceIdentifier OCClassSettingsSourceIdentifierConfidentialManager = @"confidential";

OCClassSettingsIdentifier OCClassSettingsIdentifierConfidential = @"confidential";

OCClassSettingsKey OCClassSettingsKeyAllowScreenshots = @"allow-screenshots";
OCClassSettingsKey OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings = @"allow-overwrite-confidential-mdm-settings";
OCClassSettingsKey OCClassSettingsKeyConfidentialExemptedActions = @"exempted-actions";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextOpacity = @"text-opacity";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextColor = @"text-color";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextColumnSpacing = @"text-column-spacing";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextLineSpacing = @"text-line-spacing";
OCClassSettingsKey OCClassSettingsKeyConfidentialVisibleRedactedCharacters = @"visible-redacted-characters";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowUserEmail = @"text-show-user-email";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowUserID = @"text-show-user-id";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowTimestamp = @"text-show-timestamp";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextCustomText = @"text-custom-text";
