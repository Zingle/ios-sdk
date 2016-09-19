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
             @"blockInbound" : @"block_inbound",
             @"blockOutbound" : @"block_outbound",
             @"channelType" : @"channel_type"
             };
}

+ (NSValueTransformer*)channelTypeJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ZNGChannelType.class];
}

- (BOOL) isPhoneNumber
{
    return ([self.channelType isPhoneNumberType]);
}

- (BOOL) isEmail
{
    return ([self.channelType isEmailType]);
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
    BOOL blockedStatusChanged = ((self.blockInbound != old.blockInbound) || (self.blockOutbound != old.blockOutbound));
    
    return (valueChanged || typeChanged || blockedStatusChanged);
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

- (NSString *) _displayValueWithSuppliedValue:(NSString *)value
{
    NSString * prefix = ([self.displayName length] > 0) ? self.displayName : self.channelType.displayName;
    return [NSString stringWithFormat:@"%@ - %@", prefix, value];
}

- (NSString *) displayValueUsingRawValue
{
    return [self _displayValueWithSuppliedValue:self.value];
}

- (NSString *) displayValueUsingFormattedValue
{
    return [self _displayValueWithSuppliedValue:self.formattedValue];
}

@end
