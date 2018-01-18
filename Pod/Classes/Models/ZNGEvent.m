//
//  ZNGEvent.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGEvent.h"
#import "ZNGEventViewModel.h"
#import "ZNGContact.h"
#import "ZingleValueTransformers.h"

NSString * const ZNGEventTypeMessage = @"message";
NSString * const ZNGEventTypeNote = @"note";
NSString * const ZNGEventTypeMarkConfirmed = @"mark_confirmed";
NSString * const ZNGEventTypeMarkUnconfirmed = @"mark_unconfirmed";
NSString * const ZNGEventTypeContactCreated = @"contact_created";
NSString * const ZNGEventTypeWorkflowStarted = @"workflow_started";
NSString * const ZNGEventTypeWorkflowEnded = @"workflow_ended";
NSString * const ZNGEventTypeFeedReopened = @"feed_reopened";
NSString * const ZNGEventTypeFeedClosed = @"feed_closed";
NSString * const ZNGEventTypeMessageForwarded = @"message_forward";
NSString * const ZNGEventTypeHotsosIssueCreated = @"hotsos_issue_creation";
NSString * const ZNGEventTypeAssignmentChange = @"assignment_changed";

@implementation ZNGEvent

+ (NSArray<NSString *> *) recognizedEventTypes
{
    static NSArray<NSString *> * types;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = @[
                  ZNGEventTypeMessage,
                  ZNGEventTypeNote,
                  ZNGEventTypeMarkConfirmed,
                  ZNGEventTypeMarkUnconfirmed,
                  ZNGEventTypeContactCreated,
                  ZNGEventTypeWorkflowStarted,
                  ZNGEventTypeWorkflowEnded,
                  ZNGEventTypeFeedClosed,
                  ZNGEventTypeFeedReopened,
                  ZNGEventTypeMessageForwarded,
                  ZNGEventTypeHotsosIssueCreated,
                  ZNGEventTypeAssignmentChange
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
             @"message" : @"message",
             };
}

- (id) initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    
    if (self != nil) {
        [self createViewModels];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self != nil) {
        [self createViewModels];
    }
    
    return self;
}

- (void) createViewModels
{
    NSUInteger attachmentCount = [self.message.attachments count];
    NSUInteger outgoingAttachmentCount = [self.message.outgoingImageAttachments count];
    NSMutableArray<ZNGEventViewModel *> * viewModels = [[NSMutableArray alloc] initWithCapacity:(1 + attachmentCount)];

    NSUInteger viewModelIndex = 0;
    
    // First we will make view models for any outgoing image attachments (since outgoing image attachments include both a nonsense [NSNull null] attachment object
    //  and a usuable outgoingAttachment object.
    while (viewModelIndex < outgoingAttachmentCount) {
        ZNGEventViewModel * viewModel = [[ZNGEventViewModel alloc] initWithEvent:self index:viewModelIndex];
        [viewModels addObject:viewModel];
        viewModelIndex++;
    }
    
    // If we had no outgoing attachments, we can now add the actual image attachments.
    if (outgoingAttachmentCount == 0) {
        while (viewModelIndex < attachmentCount) {
            ZNGEventViewModel * viewModel = [[ZNGEventViewModel alloc] initWithEvent:self index:viewModelIndex];
            [viewModels addObject:viewModel];
            viewModelIndex++;
        }
    }
    
    // If we had no attachments, we will always return one view model.
    // If we have a body, we also have this one more view model.
    if ((viewModelIndex == 0) || ([self.body length] > 0)) {
        ZNGEventViewModel * viewModel = [[ZNGEventViewModel alloc] initWithEvent:self index:viewModelIndex];
        [viewModels addObject:viewModel];
    }
    
    _viewModels = viewModels;
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)triggeredByUserJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGUser class]];
}

+ (NSValueTransformer*)automationJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGAutomation class]];
}

+ (NSValueTransformer*)messageJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ZNGMessage class]];
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
    event.sending = YES;
    event.eventId = message.messageId;
    event.body = message.body;
    event.eventType = ZNGEventTypeMessage;
    event.createdAt = [NSDate date];
    [event createViewModels];
    return event;
}

+ (instancetype) eventForNewNote:(NSString *)note toContact:(ZNGContact *)contact
{
    ZNGEvent * event = [[ZNGEvent alloc] init];
    event.body = note;
    event.sending = YES;
    event.eventType = ZNGEventTypeNote;
    event.contactId = contact.contactId;
    event.createdAt = [NSDate date];
    event.senderDisplayName = @"Me";
    [event createViewModels];
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

- (BOOL) isInboundMessage
{
    return (([self isMessage]) && (![self.message isOutbound]));
}

- (NSDate *) displayTime
{
    if (self.message != nil) {
        if (self.message.isDelayed) {
            // Delayed messages that have not yet been sent do not have a displayTime
            return nil;
        }
        
        // Delayed messages that have been sent (i.e. messages with a non-nil executedAt time) use executedAt for displayTime.
        // Otherwise, normal messages use the event's createdAt.  (Note: The message object itself tends to not have a createdAt time.  Thanks, server.)
        return self.message.executedAt ?: self.createdAt;
    }
    
    return self.createdAt;
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
    
    if ([self.eventType isEqualToString:ZNGEventTypeMarkConfirmed]) {
        return @"Marked read";
    } else if ([self.eventType isEqualToString:ZNGEventTypeMarkUnconfirmed]) {
        return @"Marked unread";
    } else if ([self.eventType isEqualToString:ZNGEventTypeContactCreated]) {
        return @"Contact created";
    } else if ([self.eventType isEqualToString:ZNGEventTypeWorkflowStarted]) {
        return @"Automation started";
    } else if ([self.eventType isEqualToString:ZNGEventTypeWorkflowEnded]) {
        return @"Automation ended";
    } else if ([self.eventType isEqualToString:ZNGEventTypeFeedClosed]) {
        return @"Closed";
    } else if ([self.eventType isEqualToString:ZNGEventTypeFeedReopened]) {
        return @"Reopened";
    } else if ([self.eventType isEqualToString:ZNGEventTypeMessageForwarded]) {
        return @"Message forwarded";
    } else if ([self.eventType isEqualToString:ZNGEventTypeHotsosIssueCreated]) {
        return @"HotSOS order created";
    } else if ([self.eventType isEqualToString:ZNGEventTypeAssignmentChange]) {
        NSMutableString * description;
        
        // The body should be either "unassigned" or a team/person name that was assigned
        if ([self.body isEqualToString:@"unassigned"]) {
            description = [NSMutableString stringWithString:@"Unassigned"];
        } else if ([self.body length] > 0) {
            description = [NSMutableString stringWithFormat:@"Assigned to %@", self.body];
        } else {
            description = [NSMutableString stringWithString:@"Assignment changed"];
        }
        
        // Add the user info if available.
        // It's arguable that this appending should be added to every single return value instead of just assignment.
        if (self.triggeredByUser != nil) {
            [description appendFormat:@" by %@", [self.triggeredByUser fullName]];
        }
        
        return description;
    }
    
    return @"Unknown event";
}

- (BOOL) isMutable
{
    if ([self.eventType isEqualToString:ZNGEventTypeMessage]) {
        return self.message.isDelayed;
    }
    
    return NO;
}

- (BOOL) hasChangedSince:(ZNGEvent *)oldEvent
{
    if ((![self isMutable]) && (![oldEvent isMutable])) {
        return NO;
    }
    
    return ([self.message hasChangedSince:oldEvent.message]);
}

@end
