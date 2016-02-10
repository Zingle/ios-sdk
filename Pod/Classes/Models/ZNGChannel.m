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
             @"isDefaultForType" : @"is_default_for_type",
             @"channelType" : @"channel_type"
             };
}

+ (NSValueTransformer*)channelTypeJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGChannelType.class];
}

@end
