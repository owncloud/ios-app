//
//  BrandingClassSettingsSource.h
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 11.09.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import <ownCloudSDK/ownCloudSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface BrandingClassSettingsSource : OCClassSettingsFlatSource

@property(strong,class,nonatomic,readonly,nullable) NSURL *brandingURL;
@property(strong,class,nonatomic,readonly,nullable) NSDictionary<NSString *, id> *brandingProperties;

@end

extern OCClassSettingsSourceIdentifier OCClassSettingsSourceIdentifierBranding;

NS_ASSUME_NONNULL_END
