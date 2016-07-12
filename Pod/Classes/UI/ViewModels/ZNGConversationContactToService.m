//
//  ZNGConversationContactToService.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationContactToService.h"
#import "ZNGContactService.h"
#import "ZNGLogging.h"
#import "ZNGEvent.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGConversationContactToService
{
    NSString * contactChannelValue;
    NSString * channelTypeId;
    ZNGContactService * contactService;
}

- (instancetype) initFromContactChannelValue:(NSString *)aContactChannelValue
                               channelTypeId:(NSString *)aChannelTypeId
                                   contactId:(NSString *)aContactId
                            toContactService:(ZNGContactService *)aContactService
                           withMessageClient:(ZNGMessageClient*)messageClient
                                 eventClient:(ZNGEventClient *)eventClient
{
    self = [super initWithMessageClient:messageClient eventClient:eventClient];
    
    if (self != nil) {
        contactChannelValue = aContactChannelValue;
        channelTypeId = aChannelTypeId;
        contactId = aContactId;
        contactService = aContactService;
    }
    
    return self;
}

- (NSString *)remoteName
{
    return contactService.serviceDisplayName;
}

- (void) addSenderNameToMessageEvents:(NSArray<ZNGEvent *> *)events;
{
    for (ZNGEvent * event in events) {
        if (![event isMessage]) {
            continue;
        }
        
        if ([event.message isOutbound]) {
            event.message.senderDisplayName = [self remoteName];
        } else {
            event.message.senderDisplayName = @"Me";
        }
    }
}

- (ZNGNewMessage *)freshMessage
{
    ZNGNewMessage * message = [[ZNGNewMessage alloc] init];
    message.sender = [self sender];
    message.recipients = @[[self receiver]];
    message.channelTypeIds = @[channelTypeId];
    message.senderType = ZNGConversationParticipantTypeContact;
    message.recipientType = ZNGConversationParticipantTypeService;
    return message;
}

- (ZNGParticipant *)sender
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.participantId = contactId;
    participant.channelValue = contactChannelValue;
    return participant;
}

- (ZNGParticipant *)receiver
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.participantId = contactService.serviceId;
    return participant;
}

- (NSString *)meId
{
    return contactId;
}

- (void) deleteMessage:(ZNGMessage *)message
{
    if (message == nil) {
        ZNGLogError(@"Tried to delete a nil message.");
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
        ZNGLogWarn(@"Unable to delete message %@: %@", message.messageId, error);
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
        ZNGLogWarn(@"Unable to delete messages for contact ID %@: %@", contactId, error);
    }];
}


@end
