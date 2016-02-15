//
//  ZNGMessage.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGMessage.h"
#import "ZingleValueTransformers.h"

@implementation ZNGMessage

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"messageId" : @"id",
             @"body" : @"body",
             @"displayName" : @"display_name",
             @"communicationDirection" : @"communication_direction",
             @"bodyLanguageCode" : @"body_language_code",
             @"translatedBody" : @"translated_body",
             @"translatedBodyLanguageCode" : @"translated_body_language_code",
             @"triggeredByUserId" : @"triggered_by_user_id",
             @"templateId" : @"template_id",
             @"senderType" : @"sender_type",
             @"sender" : @"sender",
             @"recipientType" : @"recipient_type",
             @"recipient" : @"recipient",
             @"attachments" : @"attachments",
             @"createdAt" : @"created_at",
             @"readAt" : @"read_at"
             };
}

+ (NSValueTransformer*)senderJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGCorrespondent.class];
}

+ (NSValueTransformer*)recipientJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGCorrespondent.class];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)readAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

@end
