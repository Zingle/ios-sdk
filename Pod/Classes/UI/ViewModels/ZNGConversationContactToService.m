//
//  ZNGConversationContactToService.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationContactToService.h"
#import "ZNGContactService.h"

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
{
    self = [super initWithMessageClient:messageClient];
    
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

- (void) addSenderNameToMessages:(NSArray<ZNGMessage *> *)messages
{
    for (ZNGMessage * message in messages) {
        if ([message isOutbound]) {
            message.senderDisplayName = [self remoteName];
        } else {
            message.senderDisplayName = @"Me";
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

@end
