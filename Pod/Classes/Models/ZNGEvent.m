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
static NSString * const ZNGEventConversationStarred = @"starred";
static NSString * const ZNGEventConversationUnstarred = @"unstarred";
static NSString * const ZNGEventWorkflowStarted = @"workflow_started";
static NSString * const ZNGEventWorkflowEnded = @"workflow_ended";
static NSString * const ZNGEventFeedReopened = @"feed_reopened";
static NSString * const ZNGEventFeedClosed = @"feed_closed";

@implementation ZNGEvent

+ (NSArray<NSString *> *) recognizedEventTypes
{
    static NSArray<NSString *> * types;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = @[
                  ZNGEventTypeMessage,
                  ZNGEventTypeNote,
                  ZNGEventMarkConfirmed,
                  ZNGEventMarkUnconfirmed,
                  ZNGEventContactCreated,
                  ZNGEventConversationStarred,
                  ZNGEventConversationUnstarred,
                  ZNGEventWorkflowStarted,
                  ZNGEventWorkflowEnded,
                  ZNGEventFeedClosed,
                  ZNGEventFeedReopened
                  ];
    });
    
    return types;
}

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
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGUser class]];
}

+ (NSValueTransformer*)automationJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGAutomation class]];
}

+ (NSValueTransformer*)messageJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGMessage class]];
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
    event.createdAt = [NSDate date];
    return event;
}

+ (instancetype) eventForNewNote:(NSString *)note toContact:(ZNGContact *)contact
{
    ZNGEvent * event = [[ZNGEvent alloc] init];
    event.body = note;
    event.eventType = ZNGEventTypeNote;
    event.contactId = contact.contactId;
    event.createdAt = [NSDate date];
    event.senderDisplayName = @"Me";
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
    return self.message.sender.correspondentId ?: self.triggeredByUser.userId;
}

- (NSString *)senderDisplayName
{
    if (_senderDisplayName != nil) {
        return _senderDisplayName;
    }
    
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
    return NO;
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
    } else if ([self.eventType isEqualToString:ZNGEventConversationStarred]) {
        return @"Conversation starred";
    } else if ([self.eventType isEqualToString:ZNGEventConversationUnstarred]) {
        return @"Conversation unstarred";
    } else if ([self.eventType isEqualToString:ZNGEventWorkflowStarted]) {
        return @"Automation started";
    } else if ([self.eventType isEqualToString:ZNGEventWorkflowEnded]) {
        return @"Automation ended";
    } else if ([self.eventType isEqualToString:ZNGEventFeedClosed]) {
        return @"Closed";
    } else if ([self.eventType isEqualToString:ZNGEventFeedReopened]) {
        return @"Reopened";
    }
    
    return @"Unknown event";
}

- (NSAttributedString *) attributedText
{
    if ([self isMessage]) {
        return [self.message attributedText];
    }
    
    return [[NSAttributedString alloc] initWithString:[self text]];
}

@end
