//
//  ZNGNewContactFieldOption.m
//  Pods
//
//  Created by Ryan Farley on 3/22/16.
//
//

#import "ZNGNewContactFieldOption.h"

@implementation ZNGNewContactFieldOption

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"selectedCustomFieldOptionId" : @"selected_custom_field_option_id",
             @"customFieldId" : @"custom_field_id"
             };
}

@end
