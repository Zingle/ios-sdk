//
//  ZNGNewContactFieldValue.m
//  Pods
//
//  Created by Ryan Farley on 3/21/16.
//
//

#import "ZNGNewContactFieldValue.h"

@implementation ZNGNewContactFieldValue

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"value" : @"value",
             @"selectedCustomFieldOptionId" : @"selected_custom_field_option_id",
             @"customFieldId" : @"custom_field_id"
             };
}

@end
