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

- (BOOL) isEqual:(ZNGEvent *)other {
    if (![other isKindOfClass:[ZNGEvent class]]) {
        return NO;
    }
    
    return [self.eventId isEqualToString:other.eventId];
}

- (NSUInteger) hash
{
    return [self.eventId hash];
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

#pragma mark - Message data for <JSQMessageData>
- (NSString *)senderId
{
    return self.message.sender.correspondentId;
}

- (NSString *)senderDisplayName
{
    NSString * messageSenderName = [self.message senderDisplayName];
    
    if (messageSenderName == nil) {
        messageSenderName = [self.triggeredByUser fullName];
    }
    
    return messageSenderName;
}

- (NSDate *)date
{
    return self.createdAt;
}

- (BOOL) isMediaMessage
{
    return ([self.message.attachments count] > 0);
}

- (NSUInteger)messageHash
{
    return [self.body hash];
}

- (NSString *)text
{
    return self.body;
}

- (id<JSQMessageMediaData>)media
{
    [self.message downloadAttachmentsIfNecessary];
    return self.message;
}

@end
