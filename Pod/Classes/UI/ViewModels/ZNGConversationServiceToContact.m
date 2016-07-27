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
#import "ZNGEventClient.h"
#import "ZNGContactClient.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGConversationServiceToContact

- (id) initFromService:(ZNGService*)aService
             toContact:(ZNGContact *)aContact
     withCurrentUserId:(NSString *)theUserId
          usingChannel:(ZNGChannel * __nullable)aChannel
     withMessageClient:(ZNGMessageClient *)messageClient
           eventClient:(ZNGEventClient *)eventClient
         contactClient:(ZNGContactClient *)contactClient
{
    self = [super initWithMessageClient:messageClient eventClient:eventClient];
    
    if (self != nil) {
        _service = aService;
        _contact = [aContact copy]; // A copy so that we can update this contact object from push notifications
        contactId = aContact.contactId;
        _myUserId = [theUserId copy];
        _channel = aChannel;
        _contactClient = contactClient;

        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(events)) options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (id) initWithConversation:(ZNGConversationServiceToContact *)conversation
{
    return [self initFromService:conversation.service toContact:conversation.contact withCurrentUserId:conversation.myUserId usingChannel:conversation.channel withMessageClient:conversation.messageClient eventClient:conversation.eventClient contactClient:conversation.contactClient];
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(events))];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) isEqual:(ZNGConversationServiceToContact *)other
{
    if (![other isKindOfClass:[ZNGConversationServiceToContact class]]) {
        return NO;
    }
    
    return ([super isEqual:other]);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(events))]) {
        if ((self.channel == nil) && ([self.events count] > 0)) {
            self.channel = [self defaultChannelForContact];
        }
    }
}

- (NSArray<NSString *> *)eventTypes
{
    return @[@"message", @"note"];
}

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

- (ZNGChannel *) defaultChannelForContact
{
    if ([self.contact.channels count] == 0) {
        return nil;
    }
    
    // Check for an explicitly default channel
    ZNGChannel * channel = [self.contact defaultChannel];
    
    if (channel != nil) {
        return channel;
    }
    
    // There is not an explicit default.  Check for the most recent message.
    ZNGMessage * message = [self mostRecentInboundMessage];
    
    if ([self.contact.channels containsObject:message.sender.channel]) {
        return message.sender.channel;
    }
    
    // We are getting into a muddy area.  Check for a message in either direction.
    message = [self mostRecentMessage];
    channel = ([message isOutbound]) ? message.recipient.channel : message.sender.channel;
    
    if (channel != nil) {
        return channel;
    }
    
    // Things are even muddier.  There appears to be no message history with a relevant channel.  Look for a phone number channel.
    channel = [self.contact phoneNumberChannel];
    
    if (channel != nil) {
        return channel;
    }
    
    // Ummm I really don't know what channel to pick at this point.  Pick the first one!
    return [self.contact.channels firstObject];
}

- (void) addInternalNote:(NSString *)note
                 success:(void (^)(ZNGStatus* status))success
                 failure:(void (^) (ZNGError *error))failure
{
    [self.eventClient postInternalNote:note toContact:self.contact success:^(ZNGEvent *note, ZNGStatus *status) {
        [self appendEvents:@[note]];
        self.totalEventCount = self.totalEventCount + 1;
        
        if (success != nil) {
            success(status);
        }
    } failure:^(ZNGError *error) {
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

- (void) triggerAutomation:(ZNGAutomation *)automation completion:(void (^)(BOOL success))completion
{
    [self.contactClient triggerAutomationWithId:automation.automationId withContactId:self.contact.contactId success:^(ZNGStatus *status) {
        completion(YES);
    } failure:^(ZNGError *error) {
        completion(NO);
    }];
}

@end
