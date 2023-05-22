//
//  OCCore+LicenseEnvironment.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 05.12.19.
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

#import "OCCore+LicenseEnvironment.h"

@implementation OCCore (LicenseEnvironment)

- (OCLicenseEnvironment *)licenseEnvironment
{
	OCLicenseEnvironment *environment = nil;

	environment = [OCLicenseEnvironment environmentWithIdentifier:nil hostname:self.bookmark.url.host certificate:self.bookmark.certificate attributes:nil];
	environment.bookmarkUUID = self.bookmark.uuid;
	environment.core = self;

	return (environment);
}

@end
