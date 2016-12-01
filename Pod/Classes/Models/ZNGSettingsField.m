//
//  ZNGSettingsField.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGSettingsField.h"
#import "ZNGFieldOption.h"

@implementation ZNGSettingsField

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"settingId" : @"id",
             @"code" : @"code",
             @"displayName" : @"display_name",
             @"dataType" : @"data_type",
             @"options" : @"options"
             };
}

+ (NSValueTransformer*)optionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGFieldOption class]];
}

@end
