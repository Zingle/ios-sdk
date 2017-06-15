//
//  ZNGCondition.m
//  Pods
//
//  Created by Jason Neel on 6/15/17.
//
//

#import "ZNGCondition.h"

@implementation ZNGCondition

+ (NSDictionary *) JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(comparisonMethodCode)): @"comparison_method_code",
             NSStringFromSelector(@selector(comparisonSource)): @"comparison_source",
             NSStringFromSelector(@selector(comparisonValue)): @"comparison_value"
             };
}

@end
