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
             @"customFieldId" : @"custom_field_id"
             };
}

@end
