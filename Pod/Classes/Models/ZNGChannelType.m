//
//  ZNGChannelType.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGChannelType.h"

@implementation ZNGChannelType

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"channelTypeId" : @"id",
             @"typeClass" : @"type_class",
             @"displayName" : @"display_name",
             @"inboundNotificationURL" : @"inbound_notification_url",
             @"outboundNotificationURL" : @"outbound_notification_url",
             @"allowCommunications" : @"allow_communications",
             @"isGlobal" : @"is_global"
             };
}

@end
