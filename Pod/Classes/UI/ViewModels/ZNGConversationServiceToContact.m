//
//  ZNGConversationServiceToContact.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationServiceToContact.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGConversationServiceToContact
{
    ZNGContact * contact;
    ZNGService * service;
    
    NSString * myUserId;
}

- (id) initFromService:(ZNGService*)aService
             toContact:(ZNGContact *)aContact
     withCurrentUserId:(NSString *)theUserId
          usingChannel:(ZNGChannel * __nullable)aChannel
     withMessageClient:(ZNGMessageClient *)messageClient;
{
    self = [super initWithMessageClient:messageClient];
    
    if (self != nil) {
        service = aService;
        contact = aContact;
        contactId = aContact.contactId;
        myUserId = [theUserId copy];
        
        if (aChannel != nil) {
            _channel = aChannel;
        } else {
            _channel = [aContact channelForFreshOutgoingMessage];
            
            if (_channel == nil) {
                ZNGLogError(@"Unable to find a default channel for our current service.  Message sending will always fail to %@", aContact);
            }
        }
        
    }
    
    return self;
}

- (ZNGContact *)contact
{
    return contact;
}

- (NSString *)remoteName
{
    return [contact fullName];
}

- (void) addSenderNameToMessages:(NSArray<ZNGMessage *> *)messages
{
    for (ZNGMessage * message in messages) {
        if (![message isOutbound]) {
            // This message is from contact to service.  The sender is the contact.
            message.senderDisplayName = [self remoteName];
        } else {
            // This message is from service to contact.  The sender is a Zingle user.  Hopefully we can figure out specifically who it is.
            ZNGUser * sender = message.triggeredByUser;
            NSString * userId = message.triggeredByUserId;
            userId = ([userId length] > 0) ? userId : sender.userId;
            
            if ([userId length] > 0) {
                // We know who sent the message.
                if ([userId isEqualToString:myUserId]) {
                    message.senderDisplayName = @"Me";
                } else if (sender != nil) {
                    message.senderDisplayName = [sender fullName];
                }
            }
        }
    }
}

- (ZNGNewMessage *)freshMessage
{
    ZNGNewMessage * message = [[ZNGNewMessage alloc] init];
    message.sender = [self sender];
    message.recipients = @[[self receiver]];
    message.channelTypeIds = @[self.channel.channelType.channelTypeId];
    message.senderType = ZNGConversationParticipantTypeService;
    message.recipientType = ZNGConversationParticipantTypeContact;
    return message;
}

- (ZNGParticipant *)sender
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.participantId = self.messageClient.serviceId;
    participant.channelValue = [[service defaultChannelForType:self.channel.channelType] value];
    return participant;
}

- (ZNGParticipant *)receiver
{
    ZNGParticipant * participant = [[ZNGParticipant alloc] init];
    participant.channelValue = self.channel.value;
    return participant;
}

- (NSString *)meId
{
    return self.messageClient.serviceId;
}

@end
