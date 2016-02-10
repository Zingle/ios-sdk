//
//  ZNGNewServiceChannel.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewServiceChannel.h"

@implementation ZNGNewServiceChannel

- (id)initWithServiceChannel:(ZNGServiceChannel*)serviceChannel {
  self = [super init];
  
  if (self) {
    _channelTypeId = serviceChannel.channelType.channelTypeId;
    _value = serviceChannel.value;
    _country = serviceChannel.country;
    _displayName = serviceChannel.displayName;
    _isDefaultForType = serviceChannel.isDefaultForType;
  }
  
  return self;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
  return @{
    @"channelTypeId" : @"channel_type_id",
    @"value" : @"value",
    @"country" : @"country",
    @"displayName" : @"display_name",
    @"isDefaultForType" : @"is_default_for_type"
  };
}

@end
