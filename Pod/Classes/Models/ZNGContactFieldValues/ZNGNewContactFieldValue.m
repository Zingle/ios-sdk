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
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id jsonValue, BOOL *success, NSError *__autoreleasing *error) {
        return jsonValue;
    } reverseBlock:^id(NSString * localValue, BOOL *success, NSError *__autoreleasing *error) {
        if ([localValue length] == 0) {
            return [NSNull null];
        }
        
        return localValue;
    }];
}

@end
