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
#import "OCLicenseManager.h" // needed as localization "anchor"

@implementation NSString (SearchSegmenter)

- (BOOL)isQuotationMark
{
	return ([@"“”‘‛‟„‚'\"′″´˝❛❜❝❞" containsString:self]);
}

- (BOOL)hasQuotationMarkSuffix
{
	if (self.length > 0)
	{
		return ([[self substringWithRange:NSMakeRange(self.length-1, 1)] isQuotationMark]);
	}

	return (NO);
}

- (BOOL)hasQuotationMarkPrefix
{
	if (self.length > 0)
	{
		return ([[self substringWithRange:NSMakeRange(0, 1)] isQuotationMark]);
	}

	return (NO);
}

- (NSArray<NSString *> *)segmentedForSearchWithQuotationMarks:(BOOL)withQuotationMarks
{
	NSMutableArray<NSString *> *segments = [NSMutableArray new];
	NSArray<NSString *> *terms;

	if ((terms = [self componentsSeparatedByString:@" "]) != nil)
	{
		__block NSString *segmentString = nil;
		__block BOOL segmentOpen = NO;
		__block BOOL isNegated = NO;

		void (^SubmitSegment)(void) = ^{
			if (segmentString.length > 0)
			{
				if (segmentOpen && withQuotationMarks)
				{
					[segments addObject:[NSString stringWithFormat:@"%@\"%@\"", (isNegated ? @"-" : @""), segmentString]];
				}
				else
				{
					[segments addObject:(isNegated ? [@"-" stringByAppendingString:segmentString] : segmentString)];
				}
			}

			segmentString = nil;
		};

		for (NSString *inTerm in terms)
		{
			NSString *term = inTerm;
			BOOL closingSegment = NO;

			if (!segmentOpen)
			{
				isNegated = NO;
			}

			if ([term hasPrefix:@"-"])
			{
				// Negate segment
				isNegated = YES;
				term = [term substringFromIndex:1];
			}

			if ([term hasQuotationMarkPrefix])
			{
				// Submit any open segment
				SubmitSegment();

				// Start new segment
				term = [term substringFromIndex:1];
				segmentOpen = YES;
			}

			if ([term hasQuotationMarkSuffix])
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
				SubmitSegment();
				segmentOpen = NO;
			}
		}

		SubmitSegment();
	}

	return (segments);
}

@end

@implementation OCQueryCondition (SearchSegmenter)

+ (nullable NSString *)normalizeKeyword:(NSString *)keyword
{
	static dispatch_once_t onceToken;
	static NSArray<NSString *> *keywords;
	static NSDictionary<NSString *, NSString *> *keywordByLocalizedKeyword;

	dispatch_once(&onceToken, ^{
		NSBundle *localizationBundle = [NSBundle bundleForClass:OCLicenseManager.class];

		#define TranslateKeyword(keyword) [[localizationBundle localizedStringForKey:@"keyword_" keyword value:keyword table:@"Localizable"] lowercaseString] : keyword

		keywordByLocalizedKeyword = @{
			// Standalone keywords
			TranslateKeyword(@"file"),
			TranslateKeyword(@"folder"),
			TranslateKeyword(@"image"),
			TranslateKeyword(@"video"),
			TranslateKeyword(@"today"),
			TranslateKeyword(@"week"),
			TranslateKeyword(@"month"),
			TranslateKeyword(@"year"),

			// Modifier keywords
			TranslateKeyword(@"type"),
			TranslateKeyword(@"after"),
			TranslateKeyword(@"before"),
			TranslateKeyword(@"on"),
			TranslateKeyword(@"smaller"),
			TranslateKeyword(@"greater"),
			TranslateKeyword(@"owner"),

			// Suffix keywords
			TranslateKeyword(@"d"),
			TranslateKeyword(@"w"),
			TranslateKeyword(@"m"),
			TranslateKeyword(@"y")
		};

		keywords = [keywordByLocalizedKeyword allValues];
	});

	NSString *normalizedKeyword = nil;

	if (keyword != nil)
	{
		keyword = [keyword lowercaseString];

		if ((normalizedKeyword = keywordByLocalizedKeyword[keyword]) == nil)
		{
			if ([keywords containsObject:keyword])
			{
				normalizedKeyword = keyword;
			}
		}
	}

	if ((normalizedKeyword == nil) && (keyword.length == 0))
	{
		normalizedKeyword = keyword;
	}

	return (normalizedKeyword);
}

+ (instancetype)forSearchSegment:(NSString *)segmentString
{
	NSString *segmentStringLowercase = nil;
	BOOL negateCondition = NO;
	BOOL literalSearch = NO;

	if ([segmentString hasPrefix:@"-"])
	{
		negateCondition = YES;
		segmentString = [segmentString substringFromIndex:1];
	}

	if ([segmentString hasPrefix:@"\""] && [segmentString hasSuffix:@"\""] && (segmentString.length >= 2))
	{
		literalSearch = YES;
		segmentString = [segmentString substringWithRange:NSMakeRange(1, segmentString.length-2)];
	}

	if (segmentString.length == 0)
	{
		return (nil);
	}

	segmentStringLowercase = segmentString.lowercaseString;

	if ([segmentStringLowercase hasPrefix:@":"] && !literalSearch)
	{
		NSString *keyword = [segmentStringLowercase substringFromIndex:1];

		if ((keyword = [OCQueryCondition normalizeKeyword:keyword]) != nil)
		{
			if ([keyword isEqual:@"folder"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameType isEqualTo:@(OCItemTypeCollection)]]);
			}
			else if ([keyword isEqual:@"file"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameType isEqualTo:@(OCItemTypeFile)]]);
			}
			else if ([keyword isEqual:@"image"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameMIMEType startsWith:@"image/"]]);
			}
			else if ([keyword isEqual:@"video"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameMIMEType startsWith:@"video/"]]);
			}
			else if ([keyword isEqual:@"today"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeDay:0]]]);
			}
			else if ([keyword isEqual:@"week"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeWeek:0]]]);
			}
			else if ([keyword isEqual:@"month"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeMonth:0]]]);
			}
			else if ([keyword isEqual:@"year"])
			{
				return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeYear:0]]]);
			}
		}
	}

	if ([segmentStringLowercase containsString:@":"] && !literalSearch)
	{
		NSArray<NSString *> *parts = [segmentString componentsSeparatedByString:@":"];
		NSString *modifier = nil;

		if ((modifier = parts.firstObject.lowercaseString) != nil)
		{
			NSArray<NSString *> *parameters = [[segmentString substringFromIndex:modifier.length+1] componentsSeparatedByString:@","];
			NSMutableArray <OCQueryCondition *> *orConditions = [NSMutableArray new];
			NSString *modifierKeyword;

			if ((modifierKeyword = [OCQueryCondition normalizeKeyword:modifier]) != nil)
			{
				for (NSString *parameter in parameters)
				{
					if (parameter.length > 0)
					{
						OCQueryCondition *condition = nil;

						if ([modifierKeyword isEqual:@"type"])
						{
							condition = [OCQueryCondition where:OCItemPropertyNameName endsWith:[@"." stringByAppendingString:parameter]];
						}
						else if ([modifierKeyword isEqual:@"after"])
						{
							NSDate *afterDate;

							if ((afterDate = [NSDate dateFromKeywordString:parameter]) != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:afterDate];
							}
						}
						else if ([modifierKeyword isEqual:@"before"])
						{
							NSDate *beforeDate;

							if ((beforeDate = [NSDate dateFromKeywordString:parameter]) != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isLessThan:beforeDate];
							}
						}
						else if ([modifierKeyword isEqual:@"on"])
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
						else if ([modifierKeyword isEqual:@"smaller"])
						{
							NSNumber *byteCount = [parameter byteCountNumber];

							if (byteCount != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameSize isLessThan:byteCount];
							}
						}
						else if ([modifierKeyword isEqual:@"greater"])
						{
							NSNumber *byteCount = [parameter byteCountNumber];

							if (byteCount != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameSize isGreaterThan:byteCount];
							}
						}
						else if ([modifierKeyword isEqual:@"owner"])
						{
							condition = [OCQueryCondition where:OCItemPropertyNameOwnerUserName startsWith:parameter];
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

								timeLabel = [OCQueryCondition normalizeKeyword:timeLabel];

								if ([timeLabel isEqual:@"d"])
								{
									condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeDay:-numParam]];
								}
								else if ([timeLabel isEqual:@"w"])
								{
									condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeWeek:-numParam]];
								}
								else if ([timeLabel isEqual:@"m"])
								{
									condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeMonth:-numParam]];
								}
								else if ([timeLabel isEqual:@"y"])
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
					return ([OCQueryCondition negating:negateCondition condition:orConditions.firstObject]);
				}
				else if (orConditions.count > 0)
				{
					return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition anyOf:orConditions]]);
				}
				else
				{
					if ([modifierKeyword isEqual:@"type"]    ||
					    [modifierKeyword isEqual:@"after"]   ||
					    [modifierKeyword isEqual:@"before"]  ||
					    [modifierKeyword isEqual:@"on"]      ||
					    [modifierKeyword isEqual:@"greater"] ||
					    [modifierKeyword isEqual:@"smaller"] ||
					    [modifierKeyword isEqual:@"owner"]
					   )
					{
						// Modifiers without parameters
						return (nil);
					}
				}
			}
		}
	}

	return ([OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameName contains:segmentString]]);
}

+ (instancetype)fromSearchTerm:(NSString *)searchTerm
{
	NSArray<NSString *> *segments = [searchTerm segmentedForSearchWithQuotationMarks:YES];
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
