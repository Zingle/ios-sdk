//
//  ZNGNewMessage.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewMessage.h"
#import "ZNGCorrespondent.h"

@implementation ZNGNewMessage

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"senderType" : @"sender_type",
             @"sender" : @"sender",
             @"recipientType" : @"recipient_type",
             @"recipients" : @"recipients",
             @"channelTypeIds" : @"channel_type_ids",
             @"body" : @"body",
             @"attachments" : @"attachments",
             @"uuid" : @"uuid"
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGParticipant class]];
}

+ (NSValueTransformer*)recipientsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGParticipant class]];
}

@end
