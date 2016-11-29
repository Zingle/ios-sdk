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
             @"customFieldOptionId" : @"custom_field_option_id",
             @"customFieldId" : @"custom_field_id"
             };
}

+ (NSValueTransformer *)valueJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(id jsonValue) {
        return jsonValue;
    } reverseBlock:^id(NSString * localValue) {
        if ([localValue length] == 0) {
            return [NSNull null];
        }
        
        return localValue;
    }];
}

@end
