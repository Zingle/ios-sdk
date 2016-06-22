//
//  ZNGConversationServiceToContact.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationServiceToContact.h"

@implementation ZNGConversationServiceToContact
{
    ZNGContact * contact;
    ZNGChannel * channel;
}

- (id) initFromServiceToContact:(ZNGContact *)aContact withMessageClient:(ZNGMessageClient *)messageClient
{
    ZNGChannel * aChannel = [aContact channelForFreshOutgoingMessage];
    return [self initFromServiceToContact:aContact usingChannel:aChannel withMessageClient:messageClient];
}

- (id) initFromServiceToContact:(ZNGContact *)aContact usingChannel:(ZNGChannel *)aChannel withMessageClient:(ZNGMessageClient *)messageClient
{
    self = [super initWithMessageClient:messageClient];
    
    if (self != nil) {
        contact = aContact;
        contactId = aContact.contactId;
        channel = aChannel;
    }
    
    return self;
}

- (NSString *)remoteName
{
    return [contact fullName];
}

- (ZNGNewMessage *)freshMessage
{
    ZNGNewMessage * message = [[ZNGNewMessage alloc] init];
    message.sender = [self sender];
    message.recipients = @[[self receiver]];
    message.channelTypeIds = @[channel.channelType.channelTypeId];
    message.senderType = ZNGConversationParticipantTypeService;
    message.recipientType = ZNGConversationParticipantTypeContact;
    return message;
}

- (ZNGParticipant *)sender
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.participantId = self.messageClient.serviceId;
    return participant;
}

- (ZNGParticipant *)receiver
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.channelValue = channel.value;
    return participant;
}

- (NSString *)meId
{
    return self.messageClient.serviceId;
}

@end
