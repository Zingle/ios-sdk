//
//  ZNGEvent.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGEvent.h"
#import "ZNGContact.h"
#import "ZingleValueTransformers.h"

static NSString * const ZNGEventTypeMessage = @"message";
static NSString * const ZNGEventTypeNote = @"note";
static NSString * const ZNGEventMarkConfirmed = @"mark_confirmed";
static NSString * const ZNGEventMarkUnconfirmed = @"mark_unconfirmed";
static NSString * const ZNGEventContactCreated = @"contact_created";

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

+ (instancetype) eventForNewNote:(NSString *)note toContact:(ZNGContact *)contact
{
    ZNGEvent * event = [[ZNGEvent alloc] init];
    event.body = note;
    event.eventType = ZNGEventTypeNote;
    event.contactId = contact.contactId;
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
    return [self.eventId hash];
}

- (NSString *)text
{
    if (([self isMessage]) || ([self isNote])) {
        return self.body;
    }
    
    if ([self.eventType isEqualToString:ZNGEventMarkConfirmed]) {
        return @"Confirmed";
    } else if ([self.eventType isEqualToString:ZNGEventMarkUnconfirmed]) {
        return @"Unconfirmed";
    } else if ([self.eventType isEqualToString:ZNGEventContactCreated]) {
        return @"Contact created";
    }
    
    return @"Unknown event";
}

- (id<JSQMessageMediaData>)media
{
    [self.message downloadAttachmentsIfNecessary];
    return self.message;
}

@end
