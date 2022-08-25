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

- (NSArray<OCSearchSegment *> *)segmentedForSearchWithQuotationMarks:(BOOL)withQuotationMarks cursorPosition:(NSNumber *)inCursorPosition
{
	NSMutableArray<OCSearchSegment *> *searchSegments = [NSMutableArray new];
	NSArray<NSString *> *terms;

	if ((terms = [self componentsSeparatedByString:@" "]) != nil)
	{
		__block NSString *segmentString = nil;
		__block BOOL segmentOpen = NO;
		__block BOOL isNegated = NO;
		__block NSRange termRange = NSMakeRange(0, 0);
		NSUInteger termOffset = 0;

		void (^SubmitSegment)(void) = ^{
			if (segmentString.length > 0)
			{
				OCSearchSegment *segment = [OCSearchSegment new];

				segment.range = termRange;
				segment.originalString = [self substringWithRange:termRange];
				segment.cursorOffset = -1;

				if (inCursorPosition != nil)
				{
					NSUInteger cursorPosition = inCursorPosition.unsignedIntegerValue;

					if ((cursorPosition > termRange.location) && (cursorPosition <= (termRange.location + termRange.length)))
					{
						segment.hasCursor = YES;
						segment.cursorOffset = cursorPosition - termRange.location;
					}
				}

				if (segmentOpen && withQuotationMarks)
				{
					segment.segmentedString = [NSString stringWithFormat:@"%@\"%@\"", (isNegated ? @"-" : @""), segmentString];
				}
				else
				{
					segment.segmentedString = isNegated ? [@"-" stringByAppendingString:segmentString] : segmentString;
				}

				[searchSegments addObject:segment];
			}

			segmentString = nil;
		};

		for (NSString *inTerm in terms)
		{
			NSString *term = inTerm;
			BOOL closingSegment = NO;

			termRange.location += termOffset;
			termRange.length = inTerm.length;

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
				termRange.location -= (segmentString.length + 1);
				termRange.length   += (segmentString.length + 1);
				segmentString = [segmentString stringByAppendingFormat:@" %@", term];
			}

			// Submit closed segments
			if (closingSegment)
			{
				SubmitSegment();
				segmentOpen = NO;
			}

			termOffset = termRange.length + 1;
		}

		SubmitSegment();
	}

	return (searchSegments);
}

- (NSArray<NSString *> *)segmentedForSearchWithQuotationMarks:(BOOL)withQuotationMarks
{
	NSArray<OCSearchSegment *> *searchSegments = [self segmentedForSearchWithQuotationMarks:withQuotationMarks cursorPosition:nil];

	return ([searchSegments arrayUsingMapper:^NSString* _Nullable(OCSearchSegment*  _Nonnull segment) {
		return (segment.segmentedString);
	}]);
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
	NSString *searchSegment = segmentString;
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
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameType isEqualTo:@(OCItemTypeCollection)]] withSymbolName:@"folder" localizedDescription:(negateCondition ? OCLocalized(@"No folder") : OCLocalized(@"Folder")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"file"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameType isEqualTo:@(OCItemTypeFile)]] withSymbolName:@"doc" localizedDescription:(negateCondition ? OCLocalized(@"No file") : OCLocalized(@"File")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"image"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameMIMEType startsWith:@"image/"]] withSymbolName:@"photo" localizedDescription:(negateCondition ? OCLocalized(@"No image") : OCLocalized(@"Image")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"video"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameMIMEType startsWith:@"video/"]] withSymbolName:@"film" localizedDescription:(negateCondition ? OCLocalized(@"No video") : OCLocalized(@"Video")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"today"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeDay:0]]] withSymbolName:@"calendar" localizedDescription:(negateCondition ? OCLocalized(@"Before today") : OCLocalized(@"Today")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"week"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeWeek:0]]] withSymbolName:@"calendar" localizedDescription:(negateCondition ? OCLocalized(@"Before this week") : OCLocalized(@"This week")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"month"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeMonth:0]]] withSymbolName:@"calendar" localizedDescription:(negateCondition ? OCLocalized(@"Before this month") : OCLocalized(@"This month")) searchSegment:searchSegment]);
			}
			else if ([keyword isEqual:@"year"])
			{
				return ([[OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:[NSDate startOfRelativeYear:0]]] withSymbolName:@"calendar" localizedDescription:(negateCondition ? OCLocalized(@"Before this year") : OCLocalized(@"This year")) searchSegment:searchSegment]);
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
				__block NSString *symbolName = nil;
				__block NSString *localizedStart = nil;
				__block NSString *localizedParameterDescriptions = nil;

				void (^ComposeAndSetDescription)(OCQueryCondition *condition, NSString *symName, NSString *descStart, NSString *paramDesc) = ^(OCQueryCondition *condition, NSString *symName, NSString *descStart, NSString *paramDesc) {
					condition.symbolName = symbolName;
					condition.localizedDescription = [NSString stringWithFormat:@"%@%@%@", ((descStart != nil) ? descStart : @""), (((descStart != nil) && (paramDesc != nil)) ? @" " : @""), ((paramDesc != nil) ? paramDesc : @"")];
				};

				void (^AddDescription)(OCQueryCondition *condition, NSString *symName, NSString *descStart, NSString *paramDesc) = ^(OCQueryCondition *condition, NSString *symName, NSString *descStart, NSString *paramDesc) {
					symbolName = symName;
					localizedStart = descStart;

					if (localizedParameterDescriptions == nil) {
						localizedParameterDescriptions = paramDesc;
					} else {
						localizedParameterDescriptions = [NSString stringWithFormat:@"%@, %@", localizedParameterDescriptions, paramDesc];
					}

					ComposeAndSetDescription(condition, symName, descStart, paramDesc);
				};

				for (NSString *parameter in parameters)
				{
					if (parameter.length > 0)
					{
						OCQueryCondition *condition = nil;

						if ([modifierKeyword isEqual:@"type"])
						{
							condition = [OCQueryCondition where:OCItemPropertyNameName endsWith:[@"." stringByAppendingString:parameter]];
							AddDescription(condition, @"circlebadge.fill", nil, parameter);
						}
						else if ([modifierKeyword isEqual:@"after"])
						{
							NSDate *afterDate;

							if ((afterDate = [NSDate dateFromKeywordString:parameter]) != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:afterDate];
								AddDescription(condition, @"calendar", negateCondition ? OCLocalized(@"Before") : OCLocalized(@"After"), [afterDate localizedStringWithTemplate:@"MMM d, yy" locale:nil]);
							}
						}
						else if ([modifierKeyword isEqual:@"before"])
						{
							NSDate *beforeDate;

							if ((beforeDate = [NSDate dateFromKeywordString:parameter]) != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameLastModified isLessThan:beforeDate];
								AddDescription(condition, @"calendar", negateCondition ? OCLocalized(@"After") : OCLocalized(@"Before"), [beforeDate localizedStringWithTemplate:@"MMM d, yy" locale:nil]);
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
								AddDescription(condition, @"calendar", negateCondition ? OCLocalized(@"Not on") : OCLocalized(@"On"), [onStartDate localizedStringWithTemplate:@"MMM d, yy" locale:nil]);
							}
						}
						else if ([modifierKeyword isEqual:@"smaller"])
						{
							NSNumber *byteCount = [parameter byteCountNumber];

							if (byteCount != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameSize isLessThan:byteCount];
								AddDescription(condition, negateCondition ? @"greaterthan.square" : @"lessthan.square", nil, [NSByteCountFormatter stringFromByteCount:byteCount.longLongValue countStyle:NSByteCountFormatterCountStyleFile]);
							}
						}
						else if ([modifierKeyword isEqual:@"greater"])
						{
							NSNumber *byteCount = [parameter byteCountNumber];

							if (byteCount != nil)
							{
								condition = [OCQueryCondition where:OCItemPropertyNameSize isGreaterThan:byteCount];
								AddDescription(condition, negateCondition ? @"lessthan.square" : @"greaterthan.square", nil, [NSByteCountFormatter stringFromByteCount:byteCount.longLongValue countStyle:NSByteCountFormatterCountStyleFile]);
							}
						}
						else if ([modifierKeyword isEqual:@"owner"])
						{
							condition = [OCQueryCondition where:OCItemPropertyNameOwnerUserName startsWith:parameter];
							AddDescription(condition, @"person.crop.circle", nil, negateCondition ? [OCLocalized(@"Not") stringByAppendingFormat:@" %@", parameter] : parameter);
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
								NSString *localizedDescription = nil;
								NSDate *greaterThanDate = nil;

								timeLabel = [OCQueryCondition normalizeKeyword:timeLabel];

								if ([timeLabel isEqual:@"d"])
								{
									greaterThanDate = [NSDate startOfRelativeDay:-numParam];
									if (negateCondition)
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"Before today") : ((numParam == 1) ? OCLocalized(@"Before yesterday") : [NSString stringWithFormat:OCLocalized(@">%d days ago"), numParam]);
									}
									else
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"Today") : ((numParam == 1) ? OCLocalized(@"Since yesterday") : [NSString stringWithFormat:OCLocalized(@"Last %d days"), numParam]);
									}
								}
								else if ([timeLabel isEqual:@"w"])
								{
									greaterThanDate = [NSDate startOfRelativeWeek:-numParam];
									if (negateCondition)
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"Before this week") : ((numParam == 1) ? OCLocalized(@"Before last week") : [NSString stringWithFormat:OCLocalized(@">%d weeks ago"), numParam]);
									}
									else
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"This week") : ((numParam == 1) ? OCLocalized(@"Since last week") : [NSString stringWithFormat:OCLocalized(@"Last %d weeks"), numParam]);
									}
								}
								else if ([timeLabel isEqual:@"m"])
								{
									greaterThanDate = [NSDate startOfRelativeMonth:-numParam];
									if (negateCondition)
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"Before this month") : ((numParam == 1) ? OCLocalized(@"Before last month") : [NSString stringWithFormat:OCLocalized(@"> %d months ago"), numParam]);
									}
									else
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"This month") : ((numParam == 1) ? OCLocalized(@"Since last month") : [NSString stringWithFormat:OCLocalized(@"Last %d months"), numParam]);
									}
								}
								else if ([timeLabel isEqual:@"y"])
								{
									greaterThanDate = [NSDate startOfRelativeYear:-numParam];
									if (negateCondition)
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"Before this year") : ((numParam == 1) ? OCLocalized(@"Before last year") : [NSString stringWithFormat:OCLocalized(@"> %d years ago"), numParam]);
									}
									else
									{
										localizedDescription = (numParam == 0) ? OCLocalized(@"This year") : ((numParam == 1) ? OCLocalized(@"Since last year") : [NSString stringWithFormat:OCLocalized(@"Last %d years"), numParam]);
									}
								}

								if (greaterThanDate != nil)
								{
									condition = [[OCQueryCondition where:OCItemPropertyNameLastModified isGreaterThan:greaterThanDate] withSymbolName:@"calendar" localizedDescription:localizedDescription searchSegment:nil];
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
					OCQueryCondition *composedCondition = [OCQueryCondition negating:negateCondition condition:orConditions.firstObject];

					composedCondition.searchSegment = searchSegment;
					return (composedCondition);
				}
				else if (orConditions.count > 0)
				{
					OCQueryCondition *composedCondition = [OCQueryCondition negating:negateCondition condition:[OCQueryCondition anyOf:orConditions]];

					ComposeAndSetDescription(composedCondition, symbolName, localizedStart, localizedParameterDescriptions);

					composedCondition.searchSegment = searchSegment;
					return (composedCondition);
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

	OCQueryCondition *nameCondition = [OCQueryCondition negating:negateCondition condition:[OCQueryCondition where:OCItemPropertyNameName contains:segmentString]];
	nameCondition.searchSegment = searchSegment;
	return (nameCondition);
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

@implementation OCQueryCondition (SearchSegmentDescription)

- (void)setValue:(id)value forMutableUserInfoKey:(OCQueryConditionUserInfoKey)key
{
	NSMutableDictionary<OCQueryConditionUserInfoKey, id> *userInfo = nil;

	if ((userInfo = (NSMutableDictionary *)self.userInfo) != nil)
	{
		if (![userInfo isKindOfClass:NSMutableDictionary.class])
		{
			userInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
		}
	}
	else
	{
		userInfo = [NSMutableDictionary new];
	}

	userInfo[key] = value;

	self.userInfo = userInfo;

}

- (NSString *)symbolName
{
	return (self.userInfo[OCQueryConditionUserInfoKeySymbolName]);
}

- (void)setSymbolName:(NSString *)symbolName
{
	[self setValue:symbolName forMutableUserInfoKey:OCQueryConditionUserInfoKeySymbolName];
}

- (NSString *)localizedDescription
{
	return (self.userInfo[OCQueryConditionUserInfoKeyLocalizedDescription]);
}

- (void)setLocalizedDescription:(NSString *)localizedDescription
{
	[self setValue:localizedDescription forMutableUserInfoKey:OCQueryConditionUserInfoKeyLocalizedDescription];
}

- (NSString *)searchSegment
{
	return (self.userInfo[OCQueryConditionUserInfoKeySearchSegment]);
}

- (void)setSearchSegment:(NSString *)searchSegment
{
	[self setValue:searchSegment forMutableUserInfoKey:OCQueryConditionUserInfoKeySearchSegment];
}

- (void)_addToComposedSearchTerm:(NSMutableString *)composedSearchTerm
{
	NSString *searchSegment = self.searchSegment;

	if (searchSegment.length > 0)
	{
		if (composedSearchTerm.length > 0)
		{
			[composedSearchTerm appendFormat:@" %@", searchSegment];
		}
		else
		{
			[composedSearchTerm appendString:searchSegment];
		}
	}

	switch (self.operator)
	{
		case OCQueryConditionOperatorNegate:
		case OCQueryConditionOperatorAnd:
		case OCQueryConditionOperatorOr: {
			OCQueryCondition *containedCondition;
			NSArray<OCQueryCondition *> *containedConditions;

			if ((containedCondition = OCTypedCast(self.value, OCQueryCondition)) != nil)
			{
				[containedCondition _addToComposedSearchTerm:composedSearchTerm];
			}
			else if ((containedConditions = OCTypedCast(self.value, NSArray)) != nil)
			{
				for (OCQueryCondition *condition in containedConditions)
				{
					[condition _addToComposedSearchTerm:composedSearchTerm];
				}
			}
		}
		break;

		default:
		break;
	}
}

- (NSString *)composedSearchTerm
{
	NSMutableString *composedSearchTerm = [NSMutableString new];

	[self _addToComposedSearchTerm:composedSearchTerm];

	if (composedSearchTerm.length > 0)
	{
		return (composedSearchTerm);
	}

	return(nil);
}

- (instancetype)withSymbolName:(NSString *)symbolName localizedDescription:(NSString *)localizedDescription searchSegment:(NSString *)searchSegment
{
	self.symbolName = symbolName;
	self.localizedDescription = localizedDescription;
	self.searchSegment = searchSegment;

	return (self);
}

@end

OCQueryConditionUserInfoKey OCQueryConditionUserInfoKeySymbolName = @"symbolName";
OCQueryConditionUserInfoKey OCQueryConditionUserInfoKeyLocalizedDescription = @"localizedDescription";
OCQueryConditionUserInfoKey OCQueryConditionUserInfoKeySearchSegment = @"searchSegment";
