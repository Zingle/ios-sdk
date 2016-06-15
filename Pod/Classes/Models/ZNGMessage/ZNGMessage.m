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

- (BOOL) isEqual:(ZNGMessage *)other
{
    if (![other isKindOfClass:[ZNGMessage class]]) {
        return NO;
    }
    
    return (self.messageId == other.messageId);
}

- (BOOL) isOutbound
{
    return [self.communicationDirection isEqualToString:@"outbound"];
}

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
             @"triggeredByUser" : @"triggered_by_user",
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

+ (NSValueTransformer*)triggeredByUserJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGUser.class];
}

@end
