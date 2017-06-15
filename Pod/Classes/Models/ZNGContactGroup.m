//
//  ZNGContactGroup.m
//  Pods
//
//  Created by Jason Neel on 6/15/17.
//
//

#import "ZNGContactGroup.h"
#import "ZNGCondition.h"
#import "UIColor+ZingleSDK.h"

@implementation ZNGContactGroup

+ (NSDictionary*) JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(groupId)): @"id",
             NSStringFromSelector(@selector(displayName)): @"display_name",
             NSStringFromSelector(@selector(conditionBooleanOperator)): @"condition_boolean_operator",
             NSStringFromSelector(@selector(conditions)): @"conditions"
             };
}

+ (NSValueTransformer *) conditionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGCondition class]];
}

- (BOOL) matchesSearchTerm:(NSString *)term
{
    NSString * lowerTerm = [term lowercaseString];
    return ([[self.displayName lowercaseString] containsString:lowerTerm]);
}

// The server may eventually send us colors here.  That would be sweet.
- (UIColor *) foregroundColor
{
    return [UIColor blackColor];
}

- (UIColor *) backgroundColor
{
    return [UIColor zng_light_gray];
}


@end