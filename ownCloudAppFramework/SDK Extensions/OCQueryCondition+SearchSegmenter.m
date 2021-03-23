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
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfDay:0]]);
	}
	else if ([segmentStringLowercase isEqual:@":week"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfWeek:0]]);
	}
	else if ([segmentStringLowercase isEqual:@":month"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfMonth:0]]);
	}
	else if ([segmentStringLowercase isEqual:@":year"])
	{
		return ([OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfYear:0]]);
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

					if ([modifier isEqual:@"type"])
					{
						condition = [OCQueryCondition where:OCItemPropertyNameName endsWith:parameter];
					}
					else if ([modifier isEqual:@"days"] || [modifier isEqual:@"day"])
					{
						condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfDay:-parameter.integerValue]];
					}
					else if ([modifier isEqual:@"weeks"] || [modifier isEqual:@"week"])
					{
						condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfWeek:-parameter.integerValue]];
					}
					else if ([modifier isEqual:@"months"] || [modifier isEqual:@"month"])
					{
						condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfMonth:-parameter.integerValue]];
					}
					else if ([modifier isEqual:@"years"] || [modifier isEqual:@"year"])
					{
						condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfYear:-parameter.integerValue]];
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

							if ([timeLabel isEqual:@"d"])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfDay:-numParam]];
							}
							else if ([timeLabel isEqual:@"w"])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfWeek:-numParam]];
							}
							else if ([timeLabel isEqual:@"m"])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfMonth:-numParam]];
							}
							else if ([timeLabel isEqual:@"y"])
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfYear:-numParam]];
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
			else if ([modifier isEqual:@"type"]   ||
				 [modifier isEqual:@"days"]   || [modifier isEqual:@"day"]   ||
				 [modifier isEqual:@"weeks"]  || [modifier isEqual:@"week"]  ||
				 [modifier isEqual:@"months"] || [modifier isEqual:@"month"] ||
				 [modifier isEqual:@"years"]  || [modifier isEqual:@"year"]
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
