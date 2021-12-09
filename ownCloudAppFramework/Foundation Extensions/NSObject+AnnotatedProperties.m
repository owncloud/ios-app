//
//  NSObject+AnnotatedProperties.m
//  ownCloud
//
//  Created by Felix Schwarz on 09.09.19.
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

#import "NSObject+AnnotatedProperties.h"
#import <objc/runtime.h>

static NSString *sOCAnnotatedPropertiesKey = @"AnnotatedProperties";

@implementation NSObject (AnnotatedProperties)

- (NSMutableDictionary<NSString *, id> *)_annotatedProperties
{
	NSMutableDictionary<NSString *, id> *annotatedProperties = nil;

	if ((annotatedProperties = objc_getAssociatedObject(self, (__bridge void *)sOCAnnotatedPropertiesKey)) == nil)
	{
		annotatedProperties = [NSMutableDictionary new];

		objc_setAssociatedObject(self, (__bridge void *)sOCAnnotatedPropertiesKey, annotatedProperties, OBJC_ASSOCIATION_RETAIN);
	}

	return (annotatedProperties);
}

- (nullable id)valueForAnnotatedProperty:(NSString *)customPropertyName
{
	@synchronized(self)
	{
		return ([[self _annotatedProperties] objectForKey:customPropertyName]);
	}
}

- (void)setValue:(nullable id)value forAnnotatedProperty:(NSString *)annotatedPropertyName
{
	@synchronized(self)
	{
		[self _annotatedProperties][annotatedPropertyName] = value;
	}
}

@end
