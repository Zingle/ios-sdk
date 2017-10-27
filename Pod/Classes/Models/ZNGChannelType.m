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

- (BOOL) isEqual:(ZNGChannelType *)object
{
    if (![object isKindOfClass:[ZNGChannelType class]]) {
        return NO;
    }
    
    return ([self.channelTypeId isEqualToString:object.channelTypeId] || ([self.displayName isEqualToString:object.displayName]));
}

- (NSUInteger) hash
{
    return [self.displayName hash];
}

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

/**
 *  In a sane world, the API would tell us if a channel type should be readable/editable by a human being.
 *  We do not live in such a world, so we will assume that only phone numbers and email addresses are human editable.
 */
- (BOOL) valueIsHumanReadable
{
    // TODO: Replace this method once the API provides an alternative to checking vs. channel type class string.
    return (([self isPhoneNumberType]) || ([self isEmailType]));
}

- (BOOL) isPhoneNumberType
{
    return [self.typeClass isEqualToString:ZNGChannelTypeClassPhoneNumber];
}

- (BOOL) isEmailType
{
    return [self.typeClass isEqualToString:ZNGChannelTypeClassEmail];
}

@end
