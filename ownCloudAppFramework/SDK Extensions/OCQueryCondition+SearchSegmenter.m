//
//  OCQueryCondition+SearchSegmenter.m
//  ownCloudApp
//
//  Created by Felix Schwarz on 19.03.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2021, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

#import "OCQueryCondition+SearchSegmenter.h"
#import "NSDate+ComputedTimes.h"
#import "NSString+ByteCountParser.h"

@implementation NSString (SearchSegmenter)

- (NSArray<NSString *> *)segmentedForSearch
{
	NSMutableArray<NSString *> *segments = [NSMutableArray new];
	NSArray<NSString *> *terms;

	if ((terms = [self componentsSeparatedByString:@" "]) != nil)
	{
		__block NSString *segmentString = nil;
		__block BOOL segmentOpen = NO;

		void (^SubmitSegment)(void) = ^{
			if (segmentString.length > 0)
			{
				[segments addObject:segmentString];
			}

			segmentString = nil;
		};

		for (NSString *inTerm in terms)
		{
			NSString *term = inTerm;
			BOOL closingSegment = NO;

			if ([term hasPrefix:@"\""])
			{
				// Submit any open segment
				SubmitSegment();

				// Start new segment
				term = [term substringFromIndex:1];
				segmentOpen = YES;
			}

			if ([term hasSuffix:@"\""])
			{
				// End segment
				term = [term substringToIndex:term.length-1];
				closingSegment = YES;
			}

			// Append term to current segment
			if (segmentString.length == 0)
			{
				segmentString = term;

				if (!segmentOpen)
				{
					// Submit standalone segment
					SubmitSegment();
				}
			}
			else
			{
				// Append to segment string
				segmentString = [segmentString stringByAppendingFormat:@" %@", term];
			}

			// Submit closed segments
			if (closingSegment)
			{
				segmentOpen = NO;
				SubmitSegment();
			}
		}

		SubmitSegment();
	}

	return (segments);
}

@end

@implementation OCQueryCondition (SearchSegmenter)

+ (instancetype)forSearchSegment:(NSString *)segmentString
{
	NSString *segmentStringLowercase = segmentString.lowercaseString;

	if ([segmentStringLowercase isEqual:@":folder"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameType isEqualTo:@(OCItemTypeCollection)]);
	}
	else if ([segmentStringLowercase isEqual:@":file"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameType isEqualTo:@(OCItemTypeFile)]);
	}
	else if ([segmentStringLowercase isEqual:@":image"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameMIMEType startsWith:@"image/"]);
	}
	else if ([segmentStringLowercase isEqual:@":video"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameMIMEType startsWith:@"video/"]);
	}
	else if ([segmentStringLowercase isEqual:@":today"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeDay:0]]);
	}
	else if ([segmentStringLowercase isEqual:@":week"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeWeek:0]]);
	}
	else if ([segmentStringLowercase isEqual:@":month"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeMonth:0]]);
	}
	else if ([segmentStringLowercase isEqual:@":year"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeYear:0]]);
	}
	else if ([segmentStringLowercase containsString:@":"])
	{
		NSArray<NSString *> *parts = [segmentString componentsSeparatedByString:@":"];
		NSString *modifier;

		if ((modifier = parts.firstObject.lowercaseString) != nil)
		{
			NSArray<NSString *> *parameters = [[segmentString substringFromIndex:modifier.length+1] componentsSeparatedByString:@","];
			NSMutableArray <OCQueryCondition *> *orConditions = [NSMutableArray new];

			for (NSString *parameter in parameters)
			{
				if (parameter.length > 0)
				{
					OCQueryCondition *condition = nil;

					#define OCLocalizedKeyword(x) OCLocalized(x).lowercaseString

					if ([modifier isEqual:@"type"] || [modifier isEqual:OCLocalizedKeyword(@"type")])
					{
						condition = [OCQueryCondition where:OCItemPropertyNameName endsWith:[@"." stringByAppendingString:parameter]];
					}
					else if ([modifier isEqual:@"after"] || [modifier isEqual:OCLocalizedKeyword(@"after")])
					{
						NSDate *afterDate;

						if ((afterDate = [NSDate dateFromKeywordString:parameter]) != nil)
						{
							condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:afterDate];
						}
					}
					else if ([modifier isEqual:@"before"] || [modifier isEqual:OCLocalizedKeyword(@"before")])
					{
						NSDate *beforeDate;

						if ((beforeDate = [NSDate dateFromKeywordString:parameter]) != nil)
						{
							condition = [OCQueryCondition where:OCItemPropertyNameLastModified isLessThan:beforeDate];
						}
					}
					else if ([modifier isEqual:@"on"] || [modifier isEqual:OCLocalizedKeyword(@"on")])
					{
						NSDate *onStartDate = nil, *onEndDate = nil;

						if ((onStartDate = [NSDate dateFromKeywordString:parameter]) != nil)
						{
							onStartDate = [onStartDate dateByAddingTimeInterval:-1];
							onEndDate = [onStartDate dateByAddingTimeInterval:60*60*24+2];

							condition = [OCQueryCondition require:@[
								[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:onStartDate],
								[OCQueryCondition where:OCItemPropertyNameLastModified isLessThan:onEndDate]
							]];
						}
					}
					else if ([modifier isEqual:@"smaller"] || [modifier isEqual:OCLocalizedKeyword(@"smaller")])
					{
						NSNumber *byteCount = [parameter byteCountNumber];

						if (byteCount != nil)
						{
							condition = [OCQueryCondition where:OCItemPropertyNameSize isLessThan:byteCount];
						}
					}
					else if ([modifier isEqual:@"greater"] || [modifier isEqual:OCLocalizedKeyword(@"greater")])
					{
						NSNumber *byteCount = [parameter byteCountNumber];

						if (byteCount != nil)
						{
							condition = [OCQueryCondition where:OCItemPropertyNameSize isGreaterThan:byteCount];
						}
					}
					else if ([modifier isEqual:@""])
					{
						// Parse time formats, f.ex.: 7d, 2w, 1m, 2y
						NSString *numString = nil;

						if ((parameter.length == 1) || // :d :w :m :y
						    ((parameter.length > 1) && // :7d :2w :1m :2y
						     ((numString = [parameter substringToIndex:parameter.length-1]) != nil) &&
						     [@([numString integerValue]).stringValue isEqual:numString]
						    )
						   )
						{
							NSInteger numParam = numString.integerValue;
							NSString *timeLabel = [parameter substringFromIndex:parameter.length-1].lowercaseString;

							if ([timeLabel isEqual:@"d"] || [timeLabel isEqual:OCLocalizedKeyword(@"d")])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeDay:-numParam]];
							}
							else if ([timeLabel isEqual:@"w"] || [timeLabel isEqual:OCLocalizedKeyword(@"w")])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeWeek:-numParam]];
							}
							else if ([timeLabel isEqual:@"m"] || [timeLabel isEqual:OCLocalizedKeyword(@"m")])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeMonth:-numParam]];
							}
							else if ([timeLabel isEqual:@"y"] || [timeLabel isEqual:OCLocalizedKeyword(@"y")])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeYear:-numParam]];
							}
						}
					}

					if (condition != nil)
					{
						[orConditions addObject:condition];
					}
				}
			}

			if (orConditions.count == 1)
			{
				return (orConditions.firstObject);
			}
			else if (orConditions.count > 0)
			{
				return ([OCQueryCondition anyOf:orConditions]);
			}
			else if ([modifier isEqual:@"type"]    || [modifier isEqual:OCLocalized(@"type")]    ||
				 [modifier isEqual:@"after"]   || [modifier isEqual:OCLocalized(@"after")]   ||
				 [modifier isEqual:@"before"]  || [modifier isEqual:OCLocalized(@"before")]  ||
				 [modifier isEqual:@"on"]      || [modifier isEqual:OCLocalized(@"on")]      ||
				 [modifier isEqual:@"greater"] || [modifier isEqual:OCLocalized(@"greater")] ||
				 [modifier isEqual:@"smaller"] || [modifier isEqual:OCLocalized(@"smaller")]
				)
			{
				// Modifiers without parameters
				return (nil);
			}
		}
	}

	return ([OCQueryCondition where:OCItemPropertyNameName contains:segmentString]);
}

+ (instancetype)fromSearchTerm:(NSString *)searchTerm
{
	NSArray<NSString *> *segments = [searchTerm segmentedForSearch];
	NSMutableArray<OCQueryCondition *> *conditions = [NSMutableArray new];
	OCQueryCondition *queryCondition = nil;

	for (NSString *segment in segments)
	{
		OCQueryCondition *condition;

		if ((condition = [self forSearchSegment:segment]) != nil)
		{
			[conditions addObject:condition];
		}
	}

	if (conditions.count == 1)
	{
		queryCondition = conditions.firstObject;
	}
	else if (conditions.count > 0)
	{
		queryCondition = [OCQueryCondition require:conditions];
	}

	return (queryCondition);
}

@end
