//
//  ZNGConversationServiceToContact.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGConversationServiceToContact.h"
#import "ZNGEvent.h"
#import "ZNGEventClient.h"
#import "ZNGContactClient.h"
#import "ZNGPrinter.h"
#import "ZNGAnalytics.h"
#import "ZNGMessageForwardingRequest.h"
#import "ZNGSocketClient.h"
#import "ZingleAccountSession.h"
#import "ZNGUserAuthorization.h"

@import SBObjectiveCWrapper;

static NSString * const ChannelsKVOPath = @"contact.channels";

@implementation ZNGConversationServiceToContact
{
    NSArray<ZNGChannel *> * _usedChannels;
    NSUInteger _usedChannelTotalEventCount;
    NSUInteger _usedChannelEventCount;
}

- (id) initFromService:(ZNGService*)aService
             toContact:(ZNGContact *)aContact
     withCurrentUserId:(NSString *)theUserId
          usingChannel:(ZNGChannel * __nullable)aChannel
     withMessageClient:(ZNGMessageClient *)messageClient
           eventClient:(ZNGEventClient *)eventClient
         contactClient:(ZNGContactClient *)contactClient
          socketClient:(ZNGSocketClient *)socketClient
{
    self = [super initWithMessageClient:messageClient eventClient:eventClient];
    
    if (self != nil) {
        _service = aService;
        _contact = [aContact copy]; // A copy so that we can update this contact object from push notifications
        contactId = aContact.contactId;
        _myUserId = [theUserId copy];
        _channel = aChannel;
        _contactClient = contactClient;
        
        self.socketClient = socketClient;
        
        if (_channel == nil) {
            // Can we auto select a channel?
            _channel = [aContact defaultChannel];
        }

        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(events)) options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:ChannelsKVOPath options:NSKeyValueObservingOptionNew context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyContactSelfMutated:) name:ZNGContactNotificationSelfMutated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyConversationDataReceived:) name:ZingleConversationDataArrivedNotification object:nil];
    }
    
    return self;
}

- (id) initWithConversation:(ZNGConversationServiceToContact *)conversation
{
    self = [self initFromService:conversation.service toContact:conversation.contact withCurrentUserId:conversation.myUserId usingChannel:conversation.channel withMessageClient:conversation.messageClient eventClient:conversation.eventClient contactClient:conversation.contactClient socketClient:conversation.socketClient];
    
    if (self != nil) {
        self.lockedDescription = conversation.lockedDescription;
    }
    
    return self;
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:ChannelsKVOPath];
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
    if ([keyPath isEqualToString:ChannelsKVOPath]) {
        // We may need to update our current channel
        if (self.channel != nil) {
            NSUInteger channelIndex = [self.contact.channels indexOfObject:self.channel];
            
            if (channelIndex == NSNotFound) {
                SBLogError(@"Received a KVO update to update channels, but our current channel no longer exists in the contact's %llu channels.  Help.", (unsigned long long)[self.contact.channels count]);
                self.channel = nil;
                return;
            }
            
            ZNGChannel * updatedChannel = self.contact.channels[channelIndex];
            
            if ([updatedChannel changedSince:self.channel]) {
                SBLogDebug(@"Our current channel seems to have changed.  Updating.");
                self.channel = updatedChannel;
            }
        }
    }
}

- (ZingleAccountSession *) session
{
    return (ZingleAccountSession *)self.eventClient.session;
}

- (void) setChannel:(ZNGChannel *)channel
{
    if ((_channel != nil) && (channel != nil) && (![channel isEqual:_channel])) {
        [[ZNGAnalytics sharedAnalytics] trackChangedChannel:channel inConversation:self];
    }

    _channel = channel;
}

- (NSArray<NSString *> *)eventTypes
{
    return @[ZNGEventTypeMessage, ZNGEventTypeNote, ZNGEventTypeAssignmentChange];
}

- (NSString *)remoteName
{
    BOOL useUnformattedPhoneValue = YES;
    ZNGChannel * phoneChannel = [self.contact phoneNumberChannel];
    
    if (phoneChannel != nil) {
        useUnformattedPhoneValue = [self.service shouldDisplayRawValueForChannel:phoneChannel];
    }
    
    return [_contact fullNameUsingUnformattedPhoneNumberValue:useUnformattedPhoneValue];
}

- (void) notifyConversationDataReceived:(NSNotification *)notification
{
    if ([self notificationRelevantToThisConversation:notification]) {
        [self.contact updateRemotely];
    }
}

- (BOOL) notificationRelevantToThisConversation:(NSNotification *)notification
{
    NSString * contactId = [notification.userInfo[ZingleConversationNotificationContactIdKey] copy];
    return [contactId isEqual:self.contact.contactId];
}

- (void) notifyContactSelfMutated:(NSNotification *)notification
{
    // If it was literally our same contact instance, we can ignore it.
    if (notification.object == self.contact) {
        return;
    }
    
    // If it was an unrelated contact, we can ignore it.
    ZNGContact * updatedContact = notification.object;
    if (![updatedContact isEqualToContact:self.contact]) {
        return;
    }
    
    // Update our dude
    [_contact updateWithNewData:updatedContact];
}

- (void) addSenderNameToEvents:(NSArray<ZNGEvent *> *)events
{
    for (ZNGEvent * event in events) {
        ZNGMessage * message = event.message;
        
        if ((![event isMessage]) && (![event isNote])) {
            continue;
        }

        BOOL outbound = ([event.message isOutbound] || [event isNote]);
        
        if (!outbound) {
            // This message is from contact to service.  The sender is the contact.
            message.senderDisplayName = [self remoteName];
        } else {
            
            // If this is a pending outgoing message from us, we can shove a "Me" in there.
            if (event.sending) {
                message.senderDisplayName = @"Me";
                continue;
            }
            
            NSString * userId = event.triggeredByUser.userId ?: event.message.triggeredByUser.userId;
            ZNGUser * triggerer = message.triggeredByUser;
            
            if ([userId length] > 0) {
                // We know who sent the message.
                if ([userId isEqualToString:_myUserId]) {
                    message.senderDisplayName = @"Me";
                } else if (triggerer != nil) {
                    message.senderDisplayName = [triggerer fullName];
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
        SBLogError(@"Recipient is nil.  Unable to send message.");
        return nil;
    }
    
    if (channelTypeId == nil) {
        SBLogError(@"Channel type is nil.  Unable to send message.");
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
    participant.channelId = self.channel.channelId;
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
    
    if (message.sender.channel != nil) {
        return [self channelWithinContactMatchingChannel:message.sender.channel];
    }
    
    // We are getting into a muddy area.  Check for a message in either direction.
    message = [self mostRecentMessage];
    channel = ([message isOutbound]) ? message.recipient.channel : message.sender.channel;
    
    if (channel != nil) {
        return [self channelWithinContactMatchingChannel:channel];
    }
    
    // Things are even muddier.  There appears to be no message history with a relevant channel.  Look for a phone number channel.
    channel = [self.contact phoneNumberChannel];
    
    if (channel != nil) {
        return [self channelWithinContactMatchingChannel:channel];
    }
    
    // Ummm I really don't know what channel to pick at this point.  Pick the first one!
    return [self.contact.channels firstObject];
}

// If the provided channel exists within our contact object, where it will have more complete information, this method returns that instance.
// If not, it returns the same object.
- (ZNGChannel *) channelWithinContactMatchingChannel:(ZNGChannel *)channel
{
    NSUInteger channelIndex = [self.contact.channels indexOfObject:channel];
    
    if (channelIndex == NSNotFound) {
        SBLogInfo(@"Trying to find %@ (%@) in %@'s channels, but it does not exist.  Was this channel deleted?  Some data will probably be stale.",
                   channel.value, channel.channelType.displayName, [self.contact fullName]);
        
        return nil;
    }
    
    return self.contact.channels[channelIndex];
}

- (void) addInternalNote:(NSString *)rawNoteString
                 success:(void (^)(ZNGStatus* status))success
                 failure:(void (^)(ZNGError *error))failure
{
    NSString * noteString = [rawNoteString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([noteString length] == 0) {
        ZNGError * error = [[ZNGError alloc] initWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Cannot add an empty note" }];
        failure(error);
        return;
    }
    
    ZNGEvent * outgoingNote = [self pendingEventForOutgoingNote:noteString];
    self.loading = YES;
    
    [self appendEvents:@[outgoingNote]];
    
    [self.eventClient postInternalNote:noteString toContact:self.contact success:^(ZNGEvent *note, ZNGStatus *status) {
        // Slight delay to allow our silly elastic server to index elastically
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self _loadRecentEventsErasing:NO removingSendingEvents:YES success:^(ZNGStatus * _Nullable loadStatus) {
                if (success) {
                    success(status);
                }
            } failure:^(ZNGError * _Nullable error) {
                SBLogWarning(@"Adding the internal note succeeded, but the request to retrieve event data afterward failed.  This is probably fine: %@", error);
                
                if (success) {
                    success(status);
                }
            }];
        });
    } failure:^(ZNGError *error) {
        self.loading = NO;
        [self removeSendingEvents];
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

- (ZNGEvent *)pendingMessageEventForOutgoingMessage:(ZNGNewMessage *)newMessage
{
    ZNGEvent * event = [super pendingMessageEventForOutgoingMessage:newMessage];
    [self addAvatarToSendingEvent:event];
    return event;
}

- (ZNGEvent *)pendingEventForOutgoingNote:(NSString *)noteString
{
    ZNGEvent * event = [ZNGEvent eventForNewNote:noteString toContact:self.contact];
    [self addSenderNameToEvents:@[event]];
    [self addAvatarToSendingEvent:event];
    [event createViewModels];
    return event;
}

- (void) addAvatarToSendingEvent:(ZNGEvent *)event
{
    event.triggeredByUser = self.session.userAuthorization;
}

- (void) triggerAutomation:(ZNGAutomation *)automation completion:(void (^)(BOOL success))completion
{
    [self.contactClient triggerAutomationWithId:automation.automationId withContactId:self.contact.contactId success:^(ZNGStatus *status) {
        completion(YES);
    } failure:^(ZNGError *error) {
        completion(NO);
    }];
}

- (void) stopAutomationWithCompletion:(void (^)(BOOL success))completion
{
    [self.contactClient stopAutomationForContactId:self.contact.contactId success:^(ZNGStatus *status) {
        completion(YES);
    } failure:^(ZNGError *error) {
        completion(NO);
    }];
}

- (NSArray<ZNGChannel *> *)usedChannels
{
    // Can we use our cached data?
    if ((self.totalEventCount == _usedChannelTotalEventCount) && ([self.events count] == _usedChannelEventCount)) {
        return _usedChannels;
    }
    
    NSMutableSet<ZNGChannel *> * channels = [[NSMutableSet alloc] initWithCapacity:[self.contact.channels count]];
    
    for (ZNGEvent * event in self.events) {
        if ([event isMessage]) {
            ZNGChannel * channel = [[event.message contactCorrespondent] channel];
            
            if (channel == nil) {
                continue;
            }
            
            // If we can find an entry for this channel within the contact object, it may have more data, so we'll grab it.  If not, no big deal.
            NSUInteger index = [self.contact.channels indexOfObject:channel];
            
            if (index != NSNotFound) {
                channel = self.contact.channels[index];
            }
            
            [channels addObject:channel];
        }
    }
    
    // Cache our result
    _usedChannelTotalEventCount = self.totalEventCount;
    _usedChannelEventCount = [self.events count];
    _usedChannels = [channels allObjects];
    
    return _usedChannels;
}

#pragma mark - Typing indicators
- (void) userDidType:(NSString *)pendingInput
{
    [self.socketClient userDidType:pendingInput];
}

- (void) userClearedInput
{
    [self.socketClient userClearedInput];
}

- (void) sendMessageWithBody:(NSString *)body success:(void (^)(ZNGStatus * _Nullable))success failure:(void (^)(ZNGError * _Nullable))failure
{
    [self userClearedInput];
    [super sendMessageWithBody:body success:success failure:failure];
}

- (void) sendMessageWithBody:(NSString *)body imageData:(NSArray<NSData *> *)imageData uuid:(NSString *)uuid success:(void (^)(ZNGStatus * _Nullable))success failure:(void (^)(ZNGError * _Nullable))failure
{
    [self userClearedInput];
    [super sendMessageWithBody:body imageData:imageData uuid:uuid success:success failure:failure];
}

#pragma mark - Forwarding
- (void) forwardMessage:(ZNGMessage *)message withBody:(NSString *)body toSMS:(NSString *)phoneNumberString success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure
{
    ZNGMessageForwardingRequest * request = [self forwardingRequestForMessage:message withBody:body];
    request.recipientType = ZNGMessageForwardingRecipientTypeSMS;
    request.recipients = @[phoneNumberString];
    
    [self _sendForwardingRequest:request success:success failure:failure];
}

- (void) forwardMessage:(ZNGMessage *)message withBody:(NSString *)body toEmail:(NSString *)email success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure
{
    ZNGMessageForwardingRequest * request = [self forwardingRequestForMessage:message withBody:body];
    request.recipientType = ZNGMessageForwardingRecipientTypeEmail;
    request.recipients = @[email];
    
    [self _sendForwardingRequest:request success:success failure:failure];
}

- (void) forwardMessage:(ZNGMessage *)message withBody:(NSString *)body toHotsosWithHotsosIssueName:(NSString *)hotsosIssueName room:(NSString *)room success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure
{
    ZNGMessageForwardingRequest * request = [self forwardingRequestForMessage:message withBody:body];
    request.recipientType = ZNGMessageForwardingRecipientTypeHotsos;
    request.hotsosIssue = hotsosIssueName;
    
    if ([room length] > 0) {
        request.room = room;
    }
    
    [self _sendForwardingRequest:request success:success failure:failure];
}

- (void) forwardMessage:(ZNGMessage *)message withBody:(NSString *)body toService:(ZNGService *)service success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure
{
    ZNGMessageForwardingRequest * request = [self forwardingRequestForMessage:message withBody:body];
    request.recipientType = ZNGMessageForwardingRecipientTypeService;
    request.recipients = @[service.serviceId];
    
    [self _sendForwardingRequest:request success:success failure:failure];
}

- (void) forwardMessage:(ZNGMessage *)message withBody:(NSString *)body toPrinter:(ZNGPrinter *)printer success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure
{
    ZNGMessageForwardingRequest * request = [self forwardingRequestForMessage:message withBody:body];
    request.recipientType = ZNGMessageForwardingRecipientTypePrinter;
    request.recipients = @[printer.printerId];
    
    [self _sendForwardingRequest:request success:success failure:failure];
}

- (ZNGMessageForwardingRequest *) forwardingRequestForMessage:(ZNGMessage  *)message withBody:(NSString *)body
{
    ZNGMessageForwardingRequest * request = [[ZNGMessageForwardingRequest alloc] init];
    request.message = message;
    request.body = body;
    
    // Add room number if this looks like our same guy
    if ([[[message contactCorrespondent] correspondentId] isEqualToString:self.contact.contactId]) {
        request.room = [[self.contact roomFieldValue] value];
    }
    
    return request;
}

- (void) _sendForwardingRequest:(ZNGMessageForwardingRequest *)request success:(void (^ _Nullable)(ZNGStatus* status))success failure:(void (^ _Nullable) (ZNGError *error))failure
{
    [self.messageClient forwardMessage:request success:success failure:failure];
}

@end
