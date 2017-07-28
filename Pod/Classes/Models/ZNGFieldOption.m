//
//  ZNGOption.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGFieldOption.h"

@implementation ZNGFieldOption

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"optionId" : @"id",
             @"displayName" : @"display_name",
             @"value" : @"value",
             @"sortOrder" : @"sort_order"
             };
}

+ (MTLValueTransformer *) sortOrderJSONTransformer
{
    return [MTLValueTransformer transformerUsingReversibleBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        // Tolerate strings
        if ([value isKindOfClass:[NSString class]]) {
            return @([(NSString *)value integerValue]);
        }
        
        return value;
    }];
}

@end
