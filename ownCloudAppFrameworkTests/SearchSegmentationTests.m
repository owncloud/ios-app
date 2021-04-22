//
//  SearchSegmentationTests.m
//  ownCloudAppTests
//
//  Created by Felix Schwarz on 19.03.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ownCloudApp/ownCloudApp.h>

@interface SearchSegmentationTests : XCTestCase

@end

@implementation SearchSegmentationTests

- (void)testStringSegmentation
{
	NSDictionary<NSString *, NSArray<NSString *> *> *expectedSegmentsByStrings = @{
		@"\"Hello world\" term2" : @[
			@"Hello world",
			@"term2"
		],

		@"\"Hello" : @[
			@"Hello"
		],

		@"Hello\"" : @[
			@"Hello"
		],

		@"Hello\" \"World" : @[
			@"Hello", @"World"
		],

		@"\"Hello World \"hello world\" term3" : @[
			@"Hello World",
			@"hello world",
			@"term3"
		],

		@"\"Hello World \"term2" : @[
			@"Hello World",
			@"term2"
		],

		@"\"Hello World \"term2 \"term3" : @[
			@"Hello World",
			@"term2",
			@"term3"
		],
	};

	[expectedSegmentsByStrings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull term, NSArray<NSString *> * _Nonnull expectedSegments, BOOL * _Nonnull stop) {
		NSArray<NSString *> *segments = [term segmentedForSearchWithQuotationMarks:NO];

		XCTAssert([segments isEqual:expectedSegments], @"segments %@ doesn't match expectation %@", segments, expectedSegments);
	}];
}

- (void)testDateComputations
{
	NSLog(@"Start of day(-2):   %@", [NSDate startOfRelativeDay:-2]);
	NSLog(@"Start of day( 0):   %@", [NSDate startOfRelativeDay:0]);
	NSLog(@"Start of day(+2):   %@", [NSDate startOfRelativeDay:2]);
	NSLog(@"Start of week(-1):  %@", [NSDate startOfRelativeWeek:-1]);
	NSLog(@"Start of week( 0):  %@", [NSDate startOfRelativeWeek:0]);
	NSLog(@"Start of week(+1):  %@", [NSDate startOfRelativeWeek:1]);
	NSLog(@"Start of month(-1): %@", [NSDate startOfRelativeMonth:-1]);
	NSLog(@"Start of month( 0): %@", [NSDate startOfRelativeMonth:0]);
	NSLog(@"Start of month(+1): %@", [NSDate startOfRelativeMonth:1]);
	NSLog(@"Start of year(-1):  %@", [NSDate startOfRelativeYear:-1]);
	NSLog(@"Start of year( 0):  %@", [NSDate startOfRelativeYear: 0]);
	NSLog(@"Start of year(+1):  %@", [NSDate startOfRelativeYear:+2]);
}

@end
