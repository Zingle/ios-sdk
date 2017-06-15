//
//  ZNGContactGroup.m
//  Pods
//
//  Created by Jason Neel on 6/15/17.
//
//

#import "ZNGContactGroup.h"
#import "ZNGCondition.h"

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

@end
