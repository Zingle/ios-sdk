//
//  ZNGContactFieldValue.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGContactFieldValue.h"

@implementation ZNGContactFieldValue

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"value" : @"value",
             @"selectedCustomFieldOptionId" : @"selected_custom_field_option_id",
             @"customField" : @"custom_field"
             };
}

+ (NSValueTransformer*)customFieldJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGContactField.class];
}

@end
