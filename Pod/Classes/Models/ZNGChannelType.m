//
//  ZNGChannelType.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGChannelType.h"

static NSString * const ZNGChannelTypeClassPhoneNumber = @"PhoneNumber";
static NSString * const ZNGChannelTypeClassEmail = @"EmailAddress";
static NSString * const ZNGChannelTypeClassFacebook = @"FacebookChannel";
static NSString * const ZNGChannelTypeClassTwitter = @"TwitterChannel";
static NSString * const ZNGChannelTypeClassUserDefined = @"UserDefinedChannel";

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

- (BOOL) isPhoneNumberType
{
    return [self.typeClass isEqualToString:ZNGChannelTypeClassPhoneNumber];
}

@end
