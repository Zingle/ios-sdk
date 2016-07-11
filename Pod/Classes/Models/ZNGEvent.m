//
//  ZNGEvent.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGEvent.h"
#import "ZingleValueTransformers.h"

static NSString * const ZNGEventTypeMessage = @"message";
static NSString * const ZNGEventTypeNote = @"note";

@implementation ZNGEvent

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"eventId" : @"id",
             @"contactId" : @"contact_id",
             @"eventType" : @"event_type",
             @"body" : @"body",
             @"createdAt" : @"created_at",
             @"triggeredByUser" : @"triggered_by_user",
             @"automation" : @"automation",
             @"message" : @"message"
             };
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)triggeredByUserJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGUser.class];
}

+ (NSValueTransformer*)automationJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGAutomation.class];
}

+ (NSValueTransformer*)messageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGMessage.class];
}

+ (instancetype) eventForNewMessage:(ZNGMessage *)message
{
    ZNGEvent * event = [[ZNGEvent alloc] init];
    event.message = message;
    event.eventId = message.messageId;
    event.body = message.body;
    event.eventType = ZNGEventTypeMessage;
    return event;
}

- (BOOL) isMessage
{
    return [self.eventType isEqualToString:ZNGEventTypeMessage];
}

- (BOOL) isNote
{
    return [self.eventType isEqualToString:ZNGEventTypeNote];
}

@end
