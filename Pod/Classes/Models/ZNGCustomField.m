//
//  ZNGCustomField.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGCustomField.h"
#import "ZNGFieldOption.h"

@implementation ZNGCustomField

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"customFieldId" : @"id",
             @"displayName" : @"display_name",
             @"isGlobal" : @"is_global",
             @"options" : @"options"
             };
}

+ (NSValueTransformer *)optionsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:ZNGFieldOption.class];
}

@end
