//
//  OCQueryCondition+SearchSegmenter.h
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

#import <ownCloudSDK/ownCloudSDK.h>
#import "OCSearchSegment.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SearchSegmenter)

- (NSArray<OCSearchSegment *> *)segmentedForSearchWithQuotationMarks:(BOOL)withQuotationMarks cursorPosition:(nullable NSNumber *)inCursorPosition;
- (NSArray<NSString *> *)segmentedForSearchWithQuotationMarks:(BOOL)withQuotationMarks;

@end

@interface OCQueryCondition (SearchSegmenter)

+ (nullable instancetype)forSearchSegment:(NSString *)segmentString;
+ (nullable instancetype)fromSearchTerm:(NSString *)searchTerm;

@end

@interface OCQueryCondition (SearchSegmentDescription)

@property(strong,nonatomic,nullable) OCSymbolName symbolName; 		//!< Optional, name of symbol to use
@property(strong,nonatomic,nullable) NSString *localizedDescription; 	//!< Optional, localized description
@property(strong,nonatomic,nullable) NSString *searchSegment;		//!< Optional, search segment from which this condition was created

@property(readonly,strong,nullable) NSString *composedSearchTerm;	//!< Composes/reassembles a search term from OCQueryConditions returned from the OCQueryCondition-SearchSegmenter. Useful for persisting a query in readable form, allowing to retain its dynamic elements. (f.ex. when converting :today to an OCQueryCondition, it will always contain the day's date as reference point. Converting the term on another day will use a different date (that day's "today") in the converted query condition.)

- (instancetype)withSymbolName:(nullable NSString *)symbolName localizedDescription:(nullable NSString *)localizedDescription searchSegment:(nullable NSString *)searchSegment;

@end

extern OCQueryConditionUserInfoKey OCQueryConditionUserInfoKeySymbolName;
extern OCQueryConditionUserInfoKey OCQueryConditionUserInfoKeyLocalizedDescription;
extern OCQueryConditionUserInfoKey OCQueryConditionUserInfoKeySearchSegment;

NS_ASSUME_NONNULL_END
