//
//  ZNGContactFieldValue.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGContactFieldValue.h"

@implementation ZNGContactFieldValue

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@: %@", self.customField.displayName, self.value];
}

- (BOOL) isEqual:(ZNGContactFieldValue *)object
{
    if (![object isKindOfClass:[ZNGContactFieldValue class]]) {
        return NO;
    }
    
    return (([self.customField isEqual:object.customField]) && ([self.value isEqualToString:object.value]));
}

- (NSUInteger) hash
{
    return [self.value hash];
}

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
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ZNGContactField.class];
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    // Handle the case of value being an int.  We could reasonably ask the server to send strings only, but this is easy enough.
    if ([key isEqualToString:@"value"]) {
        
        return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(id maybeNumber) {
            if ([maybeNumber isKindOfClass:[NSNumber class]]) {
                return [maybeNumber stringValue];
            }
            
            return maybeNumber;
        } reverseBlock:^id(id valueString) {
            return valueString;
        }];
    }
    
    return nil;
}

@end
