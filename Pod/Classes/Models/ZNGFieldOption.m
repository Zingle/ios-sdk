//
//  ZNGOption.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGFieldOption.h"

@implementation ZNGFieldOption

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"optionId" : @"id",
             @"displayName" : @"display_name",
             @"value" : @"value",
             @"sortOrder" : @"sort_order"
             };
}

@end
