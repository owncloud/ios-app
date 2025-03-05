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
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings];
	return self.confidentialSettingsEnabled && ((value != nil) ? value.boolValue : YES);
}

- (CGFloat)textOpacity {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextOpacity];
	return (value != nil) ? value.floatValue : 0.6;
}

- (NSString *)textColor {
	NSString *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextColor];
	return value;
}

- (CGFloat)lineSpacing {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextLineSpacing];
	return (value != nil) ? value.floatValue : 40.0;
}

- (BOOL)showUserEmail {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextShowUserEmail];
	return (value != nil) ? value.boolValue : YES;
}

- (BOOL)showUserID {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextShowUserID];
	return (value != nil) ? value.boolValue : YES;
}

- (BOOL)showTimestamp {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextShowTimestamp];
	return (value != nil) ? value.boolValue : YES;
}

- (NSString *)customText {
	NSString *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialTextCustomText];
	return value;
}

- (NSInteger)visibleRedactedCharacters {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyConfidentialVisibleRedactedCharacters];
	return (value != nil) ? value.integerValue : 3;
}

- (BOOL)confidentialSettingsEnabled {
	return !self.allowScreenshots || self.markConfidentialViews;
}

- (NSArray<NSString *> *)disallowedActions {
	if (self.confidentialSettingsEnabled && !self.allowOverwriteConfidentialMDMSettings) {
		return @[
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
		];
	}
	return nil;
}

+ (NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	if ([identifier isEqual:OCClassSettingsIdentifierConfidential]) {
		return @{
			OCClassSettingsKeyAllowScreenshots : @YES,
			OCClassSettingsKeyMarkConfidentialViews : @NO,
			OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings : @NO,
			OCClassSettingsKeyConfidentialTextOpacity: @(0.6),
			OCClassSettingsKeyConfidentialVisibleRedactedCharacters: @(3),
			OCClassSettingsKeyConfidentialTextShowUserEmail : @YES,
			OCClassSettingsKeyConfidentialTextShowUserID : @YES,
			OCClassSettingsKeyConfidentialTextShowTimestamp : @YES
		};
	}
	return nil;
}

+ (OCClassSettingsMetadataCollection)classSettingsMetadata
{
	return (@{
		OCClassSettingsKeyAllowScreenshots : @{
			@"type" : OCClassSettingsMetadataTypeBoolean,
			@"description" : @"Controls whether screenshots are allowed or not. If not allowed confidential views will be marked as sensitive and are not visible in screenshots.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyMarkConfidentialViews : @{
			@"type" : OCClassSettingsMetadataTypeBoolean,
			@"description" : @"Controls if views which contains sensitive content contains a watermark or not.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings : @{
			@"type" : OCClassSettingsMetadataTypeBoolean,
			@"description" : @"Controls if confidential related MDM settings can be overwritten.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextOpacity : @{
			@"type" : OCClassSettingsMetadataTypeFloat,
			@"description" : @"Controls the opacity of the watermark text. Possible values: 0.0 - 1.0",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextColor : @{
			@"type" : OCClassSettingsMetadataTypeString,
			@"description" : @"Controls the color as hex value of the watermark text.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialVisibleRedactedCharacters : @{
			@"type" : OCClassSettingsMetadataTypeInteger,
			@"description" : @"Controls the number or visible characters in redacted text. Choose value -1 to do not redact text.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextShowUserEmail : @{
			@"type" : OCClassSettingsMetadataTypeBoolean,
			@"description" : @"Controls if the user email should be shown as watermark text.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextShowUserID : @{
			@"type" : OCClassSettingsMetadataTypeBoolean,
			@"description" : @"Controls if the user ID should be shown as watermark text.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextShowTimestamp : @{
			@"type" : OCClassSettingsMetadataTypeBoolean,
			@"description" : @"Controls if the current timestamp should be shown as watermark text.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
		},
		OCClassSettingsKeyConfidentialTextCustomText : @{
			@"type" : OCClassSettingsMetadataTypeString,
			@"description" : @"Controls if the given custom text should be shown as watermark text.",
			@"status" : OCClassSettingsKeyStatusAdvanced,
			@"category" : @"Confidential"
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
OCClassSettingsKey OCClassSettingsKeyMarkConfidentialViews = @"mark-confidential-views";
OCClassSettingsKey OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings = @"allow-overwrite-confidential-mdm-settings";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextOpacity = @"text-opacity";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextColor = @"text-color";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextLineSpacing = @"text-line-spacing";
OCClassSettingsKey OCClassSettingsKeyConfidentialVisibleRedactedCharacters = @"visible-redacted-characters";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowUserEmail = @"text-show-user-email";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowUserID = @"text-show-user-id";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextShowTimestamp = @"text-show-timestamp";
OCClassSettingsKey OCClassSettingsKeyConfidentialTextCustomText = @"text-custom-text";
