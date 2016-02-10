//
//  ZNGNewContactChannel.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGNewContactChannel.h"

@implementation ZNGNewContactChannel

- (id)initWithContactChannel:(ZNGContactChannel *)contactChannel
{
    self = [super init];
    if (self) {
        _channelTypeId = contactChannel.channelType.channelTypeId;
        _value = contactChannel.value;
        _country = contactChannel.country;
        _displayName = contactChannel.displayName;
        _isDefaultForType = contactChannel.isDefaultForType;
    }
    return self;
}


+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"channelTypeId" : @"channel_type_id",
             @"value" : @"value",
             @"country" : @"country",
             @"displayName" : @"display_name",
             @"isDefaultForType" : @"is_default_for_type"
             };
}

@end
