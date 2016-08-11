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

@end
