//
//  DisplaySettings.m
//  ownCloud
//
//  Created by Felix Schwarz on 21.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "DisplaySettings.h"

@implementation DisplaySettings

#pragma mark - Class settings
+ (OCClassSettingsIdentifier)classSettingsIdentifier
{
	return (OCClassSettingsIdentifierDisplay);
}

+ (NSDictionary<OCClassSettingsKey,id> *)defaultSettingsForIdentifier:(OCClassSettingsIdentifier)identifier
{
	if ([identifier isEqual:OCClassSettingsIdentifierDisplay])
	{
		return (@{
			OCClassSettingsKeyDisplayShowHiddenFiles : @(NO),
			OCClassSettingsKeyDisplayDragFiles : @(YES)
		});
	}

	return (nil);
}

#pragma mark - Singleton
+ (DisplaySettings *)sharedDisplaySettings
{
	static dispatch_once_t onceToken;
	static DisplaySettings *sharedDisplaySettings = nil;
	dispatch_once(&onceToken, ^{
		sharedDisplaySettings = [DisplaySettings new];
	});

	return (sharedDisplaySettings);
}

- (instancetype)init
{
	if ((self = [super init]) != nil)
	{
		[OCIPNotificationCenter.sharedNotificationCenter addObserver:self forName:OCIPCNotificationNameDisplaySettingsChanged withHandler:^(OCIPNotificationCenter * _Nonnull notificationCenter, DisplaySettings *displaySettings, OCIPCNotificationName  _Nonnull notificationName) {
			[displaySettings _handleDisplaySettingsChanged];
		}];

		_showHiddenFiles = [self _showHiddenFilesValue];
		_dragFiles = [self _dragFilesValue];
	}

	return (self);
}

- (void)dealloc
{
	[OCIPNotificationCenter.sharedNotificationCenter removeObserver:self forName:OCIPCNotificationNameDisplaySettingsChanged];
}

#pragma mark - Change notifications
- (void)_handleDisplaySettingsChanged
{
	[self willChangeValueForKey:@"showHiddenFiles"];
	_showHiddenFiles = [self _showHiddenFilesValue];
	[self didChangeValueForKey:@"showHiddenFiles"];

	[self willChangeValueForKey:@"dragFiles"];
	_dragFiles = [self _dragFilesValue];
	[self didChangeValueForKey:@"dragFiles"];

	[[NSNotificationCenter defaultCenter] postNotificationName:DisplaySettingsChanged object:self];
}

#pragma mark - Show hidden files
- (BOOL)_showHiddenFilesValue
{
	NSNumber *showHiddenFilesNumber;

	if ((showHiddenFilesNumber = [OCAppIdentity.sharedAppIdentity.userDefaults objectForKey:DisplaySettingsShowHiddenFilesPrefsKey]) != nil)
	{
		return (showHiddenFilesNumber.boolValue);
	}

	return ([[self classSettingForOCClassSettingsKey:OCClassSettingsKeyDisplayShowHiddenFiles] boolValue]);
}

- (void)setShowHiddenFiles:(BOOL)showHiddenFiles
{
	_showHiddenFiles = showHiddenFiles;

	[OCAppIdentity.sharedAppIdentity.userDefaults setBool:showHiddenFiles forKey:DisplaySettingsShowHiddenFilesPrefsKey];

	[OCIPNotificationCenter.sharedNotificationCenter postNotificationForName:OCIPCNotificationNameDisplaySettingsChanged ignoreSelf:YES];
}

#pragma mark - Drag files
- (BOOL)_dragFilesValue
{
	NSNumber *dragFilesNumber;

	if ((dragFilesNumber = [OCAppIdentity.sharedAppIdentity.userDefaults objectForKey:DisplaySettingsDragFilesPrefsKey]) != nil)
	{
		return (dragFilesNumber.boolValue);
	}

	return ([[self classSettingForOCClassSettingsKey:OCClassSettingsKeyDisplayDragFiles] boolValue]);
}

- (void)setDragFiles:(BOOL)dragFiles
{
	_dragFiles = dragFiles;

	[OCAppIdentity.sharedAppIdentity.userDefaults setBool:dragFiles forKey:DisplaySettingsDragFilesPrefsKey];

	[OCIPNotificationCenter.sharedNotificationCenter postNotificationForName:OCIPCNotificationNameDisplaySettingsChanged ignoreSelf:YES];
}

#pragma mark - Query updating
- (void)updateQueryWithDisplaySettings:(OCQuery *)query
{
	id<OCQueryFilter> filter;

	if ((filter = [query filterWithIdentifier:@"_displaySettings"]) != nil)
	{
		[query updateFilter:filter applyChanges:^(id<OCQueryFilter>  _Nonnull filter) {
			// Do nothing. Use -updateFilter to trigger -setNeedsRecomputation.
		}];
	}
	else
	{
		[query addFilter:self withIdentifier:@"_displaySettings"];
	}
}

#pragma mark - Query filter
- (BOOL)query:(OCQuery *)query shouldIncludeItem:(OCItem *)item
{
	BOOL includeFile = YES;

	// Show hidden files
	if (!_showHiddenFiles)
	{
		includeFile = ![item.name hasPrefix:@"."];
	}

	return (includeFile);
}

@end

NSString *DisplaySettingsShowHiddenFilesPrefsKey = @"display-show-hidden-files";
NSString *DisplaySettingsDragFilesPrefsKey = @"display-drag-files";

OCIPCNotificationName OCIPCNotificationNameDisplaySettingsChanged = @"org.owncloud.display-settings-changed";

NSNotificationName DisplaySettingsChanged = @"org.owncloud.display-settings-changed";

OCClassSettingsIdentifier OCClassSettingsIdentifierDisplay = @"display";
OCClassSettingsKey OCClassSettingsKeyDisplayShowHiddenFiles = @"show-hidden-files";
OCClassSettingsKey OCClassSettingsKeyDisplayDragFiles = @"drag-files";
