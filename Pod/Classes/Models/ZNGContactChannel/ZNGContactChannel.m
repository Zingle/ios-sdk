//
//  ZNGContactChannel.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGContactChannel.h"

@implementation ZNGContactChannel

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
  return @{
    @"contactChannelId" : @"id",
    @"displayName" : @"display_name",
    @"value" : @"value",
    @"formattedValue" : @"formatted_value",
    @"country" : @"country",
    @"isDefaultForType" : @"is_default_for_type",
    @"channelType" : @"channel_type"
  };
}

+ (NSValueTransformer*)channelTypeJSONTransformer {
  return
      [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGChannelType.class];
}

@end
