//
//  ZNGConversationContactToService.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationContactToService.h"
#import "ZNGContactService.h"
#import "ZNGEvent.h"

@import SBObjectiveCWrapper;

@implementation ZNGConversationContactToService

- (instancetype) initFromContactChannelValue:(NSString *)aContactChannelValue
                               channelTypeId:(NSString *)aChannelTypeId
                                   contactId:(NSString *)aContactId
                            toContactService:(ZNGContactService *)aContactService
                           withMessageClient:(ZNGMessageClient*)messageClient
                                 eventClient:(ZNGEventClient *)eventClient
{
    self = [super initWithMessageClient:messageClient eventClient:eventClient];
    
    if (self != nil) {
        _contactChannelValue = aContactChannelValue;
        _channelTypeId = aChannelTypeId;
        contactId = aContactId;
        _contactService = aContactService;
    }
    
    return self;
}

- (id) initWithConversation:(ZNGConversationContactToService *)conversation
{
    return [self initFromContactChannelValue:conversation.contactChannelValue channelTypeId:conversation.channelTypeId contactId:conversation->contactId toContactService:conversation.contactService withMessageClient:conversation.messageClient eventClient:conversation.eventClient];
}

- (NSString *)remoteName
{
    return _contactService.serviceDisplayName;
}

- (void) addSenderNameToEvents:(NSArray<ZNGEvent *> *)events;
{
    for (ZNGEvent * event in events) {
        if (![event isMessage]) {
            continue;
        }
        
        if ([event.message isOutbound]) {
            // If we have an employee name in the message data, we will show that.  If not, we will show the service name again.
            event.message.senderDisplayName = [event.triggeredByUser fullName] ?: [self remoteName];
            continue;
        }
        
        // We do not need to see "Me" when this could only possibly be from us.
    }
}

- (ZNGNewMessage *)freshMessage
{
    ZNGNewMessage * message = [[ZNGNewMessage alloc] init];
    message.sender = [self sender];
    message.recipients = @[[self receiver]];
    message.channelTypeIds = @[_channelTypeId];
    message.senderType = ZNGConversationParticipantTypeContact;
    message.recipientType = ZNGConversationParticipantTypeService;
    return message;
}

- (ZNGParticipant *)sender
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.participantId = contactId;
    participant.channelValue = _contactChannelValue;
    return participant;
}

- (ZNGParticipant *)receiver
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.participantId = _contactService.serviceId;
    return participant;
}

- (NSString *)meId
{
    return contactId;
}

- (void) deleteMessage:(ZNGMessage *)message
{
    if (message == nil) {
        SBLogError(@"Tried to delete a nil message.");
        return;
    }
    
    [self.messageClient deleteMessagesWithIds:@[message.messageId] success:^(ZNGStatus *status) {
        NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
        __block NSUInteger correspondingEventIndex = NSNotFound;
        
        [mutableEvents enumerateObjectsUsingBlock:^(ZNGEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([event.message isEqual:message]) {
                correspondingEventIndex = idx;
                *stop = YES;
            }
        }];
        
        if (correspondingEventIndex != NSNotFound) {
            [mutableEvents removeObjectAtIndex:correspondingEventIndex];
        }
    } failure:^(ZNGError *error) {
        SBLogWarning(@"Unable to delete message %@: %@", message.messageId, error);
    }];
}

- (void) deleteAllMessages
{
    [self.messageClient deleteAllMessagesForContactId:contactId success:^(ZNGStatus *status) {
        NSMutableArray<ZNGEvent *> * mutableEvents = [self mutableArrayValueForKey:NSStringFromSelector(@selector(events))];
        
        // Since we are using KVO notifications, we will first check if we have 100% messages.  This is the expected case, and we rather post a single
        //  KVO removal notification for all objects if possible.
        __block BOOL allMessages = YES;
        
        [mutableEvents enumerateObjectsUsingBlock:^(ZNGEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![event isMessage]) {
                allMessages = NO;
                *stop = YES;
            }
        }];
        
        if (allMessages) {
            [mutableEvents removeAllObjects];
        } else {
            for (ZNGEvent * event in self.events) {
                if ([event isMessage]) {
                    [mutableEvents removeObject:event];
                }
            }
        }
    } failure:^(ZNGError *error) {
        SBLogWarning(@"Unable to delete messages for contact ID %@: %@", self->contactId, error);
    }];
}


@end
