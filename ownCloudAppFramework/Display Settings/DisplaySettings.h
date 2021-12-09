//
//  DisplaySettings.h
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

#import <Foundation/Foundation.h>
#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface DisplaySettings : NSObject <OCClassSettingsSupport, OCQueryFilter>

#pragma mark - Singleton
@property(class,retain,nonatomic,readonly) DisplaySettings *sharedDisplaySettings;

#pragma mark - Show hidden files
@property(assign,nonatomic) BOOL showHiddenFiles;

#pragma mark - Query updating
- (void)updateQueryWithDisplaySettings:(OCQuery *)query;

@end

extern NSString *DisplaySettingsShowHiddenFilesPrefsKey;			//!< The UserDefaults Key containing the BOOL value for .showHiddenFiles

extern OCIPCNotificationName OCIPCNotificationNameDisplaySettingsChanged; 	//!< Posted when display settings changed (internal use only)
extern NSNotificationName DisplaySettingsChanged;				//!< Posted when display settings changed (for use by app + File Provider)

extern OCClassSettingsIdentifier OCClassSettingsIdentifierDisplay; 		//!< The class settings identifier for the Display Settings
extern OCClassSettingsKey OCClassSettingsKeyDisplayShowHiddenFiles;		//!< The class settings key for Show Hidden Files

NS_ASSUME_NONNULL_END
