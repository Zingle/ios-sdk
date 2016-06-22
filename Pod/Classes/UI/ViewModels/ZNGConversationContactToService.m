//
//  ZNGConversationContactToService.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationContactToService.h"

@implementation ZNGConversationContactToService
{
    NSString * contactChannelValue;
    NSString * channelTypeId;
    NSString * serviceId;
}

- (instancetype) initFromContactChannelValue:(NSString *)aContactChannelValue
                               channelTypeId:(NSString *)aChannelTypeId
                                   contactId:(NSString *)aContactId
                                 toServiceId:(NSString *)aServiceId
                           withMessageClient:(ZNGMessageClient*)messageClient
{
    self = [super initWithMessageClient:messageClient];
    
    if (self != nil) {
        contactChannelValue = aContactChannelValue;
        channelTypeId = aChannelTypeId;
        contactId = aContactId;
        serviceId = aServiceId;
    }
    
    return self;
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
    
}

@end
