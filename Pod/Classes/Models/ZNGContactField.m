//
//  ZNGContactField.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGContactField.h"
#import "ZNGFieldOption.h"

@implementation ZNGContactField

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactFieldId" : @"id",
             @"displayName" : @"display_name",
             @"dataType" : @"data_type",
             @"isGlobal" : @"is_global",
             @"options" : @"options"
             };
}

+ (NSValueTransformer*)optionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGFieldOption class]];
}


@end
