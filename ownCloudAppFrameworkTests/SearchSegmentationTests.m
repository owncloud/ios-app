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

- (void)testStringSegmentationWithCursorPosition
{
	NSArray<NSDictionary<NSString *, id> *> *testCases = @[
		@{
			@"term" : @"012 456",
			@"cursorPosition" : @(2),
			@"expectedSegments" : @[
				@"012",
				@"456"
			],
			@"expectedSegmentOffset" : @(0)
		},

		@{
			@"term" : @"012 456",
			@"cursorPosition" : @(4),
			@"expectedSegments" : @[
				@"012",
				@"456"
			],
			@"expectedSegmentOffset" : @(-1)
		},

		@{
			@"term" : @"012 456",
			@"cursorPosition" : @(5),
			@"expectedSegments" : @[
				@"012",
				@"456"
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"012 456",
			@"cursorPosition" : @(6),
			@"expectedSegments" : @[
				@"012",
				@"456"
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"012 456",
			@"cursorPosition" : @(7),
			@"expectedSegments" : @[
				@"012",
				@"456"
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"012 456 ",
			@"cursorPosition" : @(8),
			@"expectedSegments" : @[
				@"012",
				@"456"
			],
			@"expectedSegmentOffset" : @(-1)
		},

		@{
			@"term" : @"123 \"678 ",
			@"cursorPosition" : @(9),
			@"expectedSegments" : @[
				@"123",
				@"\"678 \""
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"123 \"678 X\"",
			@"cursorPosition" : @(10),
			@"expectedSegments" : @[
				@"123",
				@"\"678 X\""
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"123 \"678 X\" ",
			@"cursorPosition" : @(11),
			@"expectedSegments" : @[
				@"123",
				@"\"678 X\""
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"123 \"678 X\" ",
			@"cursorPosition" : @(12),
			@"expectedSegments" : @[
				@"123",
				@"\"678 X\""
			],
			@"expectedSegmentOffset" : @(-1)
		},

		@{
			@"term" : @"123 \"678 X ",
			@"cursorPosition" : @(11),
			@"expectedSegments" : @[
				@"123",
				@"\"678 X \""
			],
			@"expectedSegmentOffset" : @(1)
		},

		@{
			@"term" : @"123 \"678 X ",
			@"cursorPosition" : @(12),
			@"expectedSegments" : @[
				@"123",
				@"\"678 X \""
			],
			@"expectedSegmentOffset" : @(-1)
		}
	];

	for (NSDictionary<NSString *, id> *testCase in testCases)
	{
		NSString *term = testCase[@"term"];
		NSArray<NSString *> *expectedSegments = testCase[@"expectedSegments"];
		NSNumber *cursorPosition = testCase[@"cursorPosition"];
		NSNumber *expectedSegmentOffset = testCase[@"expectedSegmentOffset"];
		__block NSInteger segmentWithCursorOffset = -1;

		NSArray<OCSearchSegment *> *searchSegments = [term segmentedForSearchWithQuotationMarks:YES cursorPosition:cursorPosition];
		NSMutableArray<NSString *> *segments = [NSMutableArray new];

		[searchSegments enumerateObjectsUsingBlock:^(OCSearchSegment * _Nonnull searchSegment, NSUInteger idx, BOOL * _Nonnull stop) {
			[segments addObject:searchSegment.segmentedString];
			if (searchSegment.hasCursor)
			{
				segmentWithCursorOffset = idx;
			}
		}];

		XCTAssert([segments isEqual:expectedSegments], @"segments %@ doesn't match expectation %@", segments, expectedSegments);
		if (expectedSegmentOffset != nil)
		{
			XCTAssert((segmentWithCursorOffset == expectedSegmentOffset.integerValue), @"segment cursor offset %ld doesn't match expectation %ld for cursor position %@", segmentWithCursorOffset, expectedSegmentOffset.integerValue, cursorPosition);
		}
	}
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
