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


- (NSDictionary *) dictionaryValue
{
    NSMutableDictionary * superDict = [[super dictionaryValue] mutableCopy];
    
    if (([self.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) && ([self.value length] > 0)) {
        // Ensure that we are serialized as true or false
        superDict[NSStringFromSelector(@selector(value))] = [self.value boolValue] ? @"true" : @"false";
    }
        
    return superDict;
}

- (BOOL) isEqual:(ZNGContactFieldValue *)object
{
    if (![object isKindOfClass:[ZNGContactFieldValue class]]) {
        return NO;
    }
    
    return (([self.customField isEqual:object.customField]) && ([[self comparableValue] isEqualToString:[object comparableValue]]));
}

- (NSString *) comparableValue
{
    if ([self.customField.dataType isEqualToString:ZNGContactFieldDataTypeBool]) {
        return [@([self.value boolValue]) stringValue];
    } else if ([self.customField.dataType isEqualToString:ZNGContactFieldDataTypeNumber]) {
        return [@([self.value intValue]) stringValue];
    }
    
    return self.value;
}

- (NSUInteger) hash
{
    return [[self comparableValue] hash];
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
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGContactField class]];
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    // Handle the case of value being an int.  We could reasonably ask the server to send strings only, but this is easy enough.
    if ([key isEqualToString:@"value"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(id maybeNumber, BOOL *success, NSError *__autoreleasing *error) {
            if ([maybeNumber isKindOfClass:[NSNumber class]]) {
                return [maybeNumber stringValue];
            }
            
            return maybeNumber;
        } reverseBlock:^id(id valueString, BOOL *success, NSError *__autoreleasing *error) {
            return valueString;
        }];
    }
    
    return nil;
}

@end
