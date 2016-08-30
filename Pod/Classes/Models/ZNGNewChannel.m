//
//  ZNGNewChannel.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGNewChannel.h"

@implementation ZNGNewChannel

- (instancetype)initWithChannel:(ZNGChannel*)channel
{
    self = [super init];
    
    if (self) {
        _channelTypeId = channel.channelType.channelTypeId;
        _value = channel.value;
        _country = channel.country;
        _displayName = channel.displayName;
        _isDefaultForType = channel.isDefaultForType;
        
        // TODO: Remove this once hte server auto-detects country
#warning TODO: Remove temporary country hard-coding
        if ([_country length] == 0) {
            _country = @"US";
        }
    }
    
    return self;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey
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
