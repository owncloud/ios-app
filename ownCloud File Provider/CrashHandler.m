//
//  CrashHandler.m
//  ownCloud File Provider
//
//  Created by Michael Neuwert on 30.07.20.
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

#import <CrashReporter.h>
#import <ownCloudSDK/ownCloudSDK.h>

@interface CrashHandler : NSObject
@end

@implementation CrashHandler

+ (void)load {
	// Initialize crash reporter as soon as FP extension is loaded into memory
	PLCrashReporterConfig *configuration = [PLCrashReporterConfig defaultConfiguration];
	PLCrashReporter *reporter = [[PLCrashReporter alloc] initWithConfiguration:configuration];

	// Do we have a pending crash report from previous session?
	if ([reporter hasPendingCrashReport]) {

		// Generate a report and add it to the log file
		NSData *crashData = [reporter loadPendingCrashReportData];
		if (crashData != nil) {
			PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error:nil];
			if (report != nil) {
				NSString *crashString = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat:PLCrashReportTextFormatiOS];
				OCLogError(@"%@", crashString);
			}
		}

		// Purge the report which we just added to the log
		[reporter purgePendingCrashReport];
	}

	// Start intercepting OS signals to catch crashes
	[reporter enableCrashReporter];
}

@end
