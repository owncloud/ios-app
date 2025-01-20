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
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyMarkConfidentialViews];
	return (value != nil) ? value.boolValue : YES;
}

- (BOOL)allowOverwriteConfidentialMDMSettings {
	NSNumber *value = [ConfidentialManager classSettingForOCClassSettingsKey:OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings];
	return self.confidentialSettingsEnabled && ((value != nil) ? value.boolValue : YES);
}

- (BOOL)confidentialSettingsEnabled {
	return !self.allowScreenshots || self.markConfidentialViews;
}

- (NSArray<NSString *> *)disallowedActions {
	if (self.confidentialSettingsEnabled && !self.allowOverwriteConfidentialMDMSettings) {
		return @[
			@"com.owncloud.action.openin",
			@"com.owncloud.action.copy"
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
			OCClassSettingsKeyAllowOverwriteConfidentialMDMSettings : @NO
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
