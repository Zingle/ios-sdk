//
//  ZNGCustomFieldValues.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGCustomFieldValue.h"

@implementation ZNGCustomFieldValue

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return  @{
              @"value" : @"value",
              @"selectedCustomFieldOptionId" : @"selected_custom_field_option_id",
              @"customField" : @"custom_field"
              };
}


+ (NSValueTransformer *)customFieldJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGCustomField.class];
}

@end
