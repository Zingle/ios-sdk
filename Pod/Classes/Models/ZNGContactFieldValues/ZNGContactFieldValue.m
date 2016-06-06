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

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    // Handle the case of value being an int.  We could reasonably ask the server to send strings only, but this is easy enough.
    if ([key isEqualToString:@"value"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
            if ([value isKindOfClass:[NSNumber class]]) {
                return [value stringValue];
            }
            
            return value;
        }];
    }
    
    return nil;
}

@end
