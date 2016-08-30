//
//  ZNGChannel.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGChannel.h"

@implementation ZNGChannel

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"channelId" : @"id",
             @"displayName" : @"display_name",
             @"value" : @"value",
             @"formattedValue" : @"formatted_value",
             @"country" : @"country",
             @"isDefault" : @"is_default",
             @"isDefaultForType" : @"is_default_for_type",
             @"channelType" : @"channel_type"
             };
}

+ (NSValueTransformer*)channelTypeJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGChannelType.class];
}

- (BOOL) isPhoneNumber
{
    return ([self.channelType.typeClass isEqualToString:@"PhoneNumber"]);
}

- (NSString *) valueForComparison
{
    if ([self isPhoneNumber]) {
        NSCharacterSet * nonNumbers = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        NSString * onlyNumbers = [[self.value componentsSeparatedByCharactersInSet:nonNumbers] componentsJoinedByString:@""];
        
        if ([onlyNumbers characterAtIndex:0] == '1') {
            return [onlyNumbers substringFromIndex:1];
        }
        
        return onlyNumbers;
    }
    
    return self.value;
}

- (BOOL) changedSince:(ZNGChannel *)old
{
    BOOL valueChanged = ![[self valueForComparison] isEqualToString:[old valueForComparison]];
    BOOL typeChanged = ![self.displayName isEqualToString:old.displayName];
    
    return (valueChanged || typeChanged);
}

- (BOOL) isEqual:(ZNGChannel *)other
{
    if (![other isKindOfClass:[ZNGChannel class]]) {
        return NO;
    }
    
    return ([self.channelId isEqualToString:other.channelId]);
}

- (NSUInteger) hash
{
    return [self.channelId hash];
}

- (void) setValueFromTextEntry:(NSString *)newValue
{
    self.value = newValue;
    self.formattedValue = newValue;
}

@end
