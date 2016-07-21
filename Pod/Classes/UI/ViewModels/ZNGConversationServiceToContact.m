//
//  ZNGConversationServiceToContact.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationServiceToContact.h"
#import "ZNGLogging.h"
#import "ZNGEvent.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGConversationServiceToContact

- (id) initFromService:(ZNGService*)aService
             toContact:(ZNGContact *)aContact
     withCurrentUserId:(NSString *)theUserId
          usingChannel:(ZNGChannel * __nullable)aChannel
     withMessageClient:(ZNGMessageClient *)messageClient
       withEventClient:(ZNGEventClient *)eventClient
{
    self = [super initWithMessageClient:messageClient eventClient:eventClient];
    
    if (self != nil) {
        _service = aService;
        _contact = [aContact copy]; // A copy so that we can update this contact object from push notifications
        contactId = aContact.contactId;
        _myUserId = [theUserId copy];
        
        if (aChannel != nil) {
            _channel = aChannel;
        } else {
            _channel = [aContact channelForFreshOutgoingMessage];
            
            if (_channel == nil) {
                ZNGLogError(@"Unable to find a default channel for our current service.  Message sending will always fail to %@", aContact);
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (id) initWithConversation:(ZNGConversationServiceToContact *)conversation
{
    return [self initFromService:conversation.service toContact:conversation.contact withCurrentUserId:conversation.myUserId usingChannel:conversation.channel withMessageClient:conversation.messageClient withEventClient:conversation.eventClient];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) isEqual:(ZNGConversationServiceToContact *)other
{
    if (![other isKindOfClass:[ZNGConversationServiceToContact class]]) {
        return NO;
    }
    
    return ([super isEqual:other]);
}

// TODO: Restore this once the server starts accepting arrays of event types.
//- (NSArray<NSString *> *)eventTypes
//{
//    return @[@"message", @"note"];
//}

- (NSString *)remoteName
{
    return [_contact fullName];
}

- (void) notifyPushNotificationReceived:(NSNotification *)notification
{
    NSString * contactId = notification.userInfo[@"feedId"];
    BOOL thisPushRegardingSomeOtherContact = (([contactId length] > 0) && (![contactId isEqualToString:self.contact.contactId]));
    
    if (!thisPushRegardingSomeOtherContact) {
        [self.contact updateRemotely];
    }
}

- (void) addSenderNameToMessageEvents:(NSArray<ZNGEvent *> *)events
{
    for (ZNGEvent * event in events) {
        ZNGMessage * message = event.message;
        
        if (message == nil) {
            continue;
        }
        
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
                if ([userId isEqualToString:_myUserId]) {
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
    ZNGParticipant * recipient = [self receiver];
    NSString * channelTypeId = self.channel.channelType.channelTypeId;
    
    if (recipient == nil) {
        ZNGLogError(@"Recipient is nil.  Unable to send message.");
        return nil;
    }
    
    if (channelTypeId == nil) {
        ZNGLogError(@"Channel type is nil.  Unable to send message.");
        return nil;
    }
    
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
    participant.channelValue = [[_service defaultChannelForType:self.channel.channelType] value];
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
