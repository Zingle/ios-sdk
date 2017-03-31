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
             @"outgoingImageAttachments" : [NSNull null],
             @"uuid" : @"uuid"
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGParticipant class]];
}

+ (NSValueTransformer*)recipientsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ZNGParticipant class]];
}

@end
