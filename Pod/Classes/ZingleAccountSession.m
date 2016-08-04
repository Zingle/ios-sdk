//
//  ZingleAccountSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleAccountSession.h"
#import "ZNGLogging.h"
#import "ZNGAccount.h"
#import "ZNGService.h"
#import "ZNGAccountClient.h"
#import "ZNGEventClient.h"
#import "ZNGServiceClient.h"
#import "ZNGServiceToContactViewController.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGAutomationClient.h"
#import "ZNGContactClient.h"
#import "ZNGContactChannelClient.h"
#import "ZNGLabelClient.h"
#import "ZNGUserAuthorizationClient.h"

static const int zngLogLevel = ZNGLogLevelInfo;

// Override readonly properties with strong properties to get proper KVO
@interface ZingleAccountSession ()

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, ZNGConversationServiceToContact *> * conversationsByContactId;

@end

@implementation ZingleAccountSession
{
    ZNGAccountChooser accountChooser;
    ZNGServiceChooser serviceChooser;
    
    dispatch_semaphore_t contactClientSemaphore;
    
    ZNGAccount * _account;
    ZNGService * _service;
    
    ZNGUserAuthorization * userAuthorization;
}



- (instancetype) initWithToken:(NSString *)token key:(nonnull NSString *)key
{
    return [self initWithToken:token key:key accountChooser:nil serviceChooser:nil errorHandler:nil];
}

- (instancetype) initWithToken:(NSString *)token
                           key:(NSString *)key
                accountChooser:(nullable ZNGAccountChooser)anAccountChooser
                serviceChooser:(nullable ZNGServiceChooser)aServiceChooser
                  errorHandler:(nullable ZNGErrorHandler)errorHandler
{
    self = [super initWithToken:token key:key errorHandler:errorHandler];
    
    if (self != nil) {
        contactClientSemaphore = dispatch_semaphore_create(0);
        
        accountChooser = anAccountChooser;
        serviceChooser = aServiceChooser;
        _conversationsByContactId = [[NSMutableDictionary alloc] init];
        [self retrieveAvailableAccounts];
    }
    
    return self;
}

- (void) logout
{
    [self _unregisterForAllPushNotifications];
}

#pragma mark - Service/Account setters
- (void) setAccount:(ZNGAccount *)account
{
    if ((_account != nil) && (![_account isEqual:account])) {
        ZNGLogError(@"Account was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _account ,account);
        [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
        [self willChangeValueForKey:NSStringFromSelector(@selector(available))];
        _service = nil;
        _available = nil;
        [self didChangeValueForKey:NSStringFromSelector(@selector(available))];
        [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
    }
    
    _account = account;
    
    if (_account != nil) {
        [self updateStateForNewAccountOrService];
    }
}

- (ZNGAccount *)account
{
    if (_account != nil) {
        return _account;
    }
    
    if ([self.availableAccounts count] == 1) {
        return [self.availableAccounts firstObject];
    }
    
    return nil;
}

- (ZNGService *)service
{
    if (_service != nil) {
        return _service;
    }
    
    if ([self.availableServices count] == 1) {
        return [self.availableServices firstObject];
    }
    
    return nil;
}

- (void) setService:(ZNGService *)service
{
    if ((_service != nil) && (![_service isEqual:service])) {
        ZNGLogError(@"Service was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _service ,service);
    }
    
    NSUInteger serviceIndex = [self.availableServices indexOfObject:service];
    
    if (serviceIndex == NSNotFound) {
        ZNGLogError(@"setService was called with service ID %@, but it does not exist within our %lld available services.  Ignoring.", service.serviceId, (unsigned long long)[self.availableServices count]);
        return;
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(available))];
    _available = (service != nil);
    _service = self.availableServices[serviceIndex];
    [self didChangeValueForKey:NSStringFromSelector(@selector(available))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
    
    if (_service != nil) {
        [self updateStateForNewAccountOrService];
    }
}

- (void) setAvailableAccounts:(NSArray<ZNGAccount *> * _Nullable)availableAccounts
{
    _availableAccounts = availableAccounts;
}

- (void) setAvailableServices:(NSArray<ZNGService *> * _Nullable)availableServices
{
    _availableServices = availableServices;
}

#pragma mark - Account/Service state management
- (void) updateStateForNewAccountOrService
{
    // Do we need to select an account?
    if (self.account == nil) {
        if (self.availableAccounts == nil) {
            // We have no available accounts.  Go request them.
            [self retrieveAvailableAccounts];
        } else if (accountChooser != nil) {
            // We have just gotten a list of available accounts.
            
            // If there is anything in the list (other than the obvious case of a single available account,) we will ask our chooser to pick one
            if ([self.availableAccounts count] != 1) {
                self.account = accountChooser(self.availableAccounts);
            }
            
            accountChooser = nil;
        }
        return;
    }
    
    // Do we need to select a service?
    if (self.service == nil) {
        if (self.availableServices == nil) {
            // We have no available services.  Go request them.
            [self retrieveAvailableServices];
        } else if (serviceChooser != nil) {
            // We have just gotten a list of services
            
            // If there is anything in the list (other than the obvious case of a single available service,) we will ask our chooser to pick one
            if ([self.availableServices count] != 1) {
                self.service = serviceChooser(self.availableServices);
            }
            
            serviceChooser = nil;
        }
        return;
    }
    
    // We now have both an account and a service selected.
    
    [self initializeAllClients];
    [self retrieveUserObject];
}

- (void) initializeAllClients
{
    NSString * serviceId = self.service.serviceId;
    
    self.automationClient = [[ZNGAutomationClient alloc] initWithSession:self serviceId:serviceId];
    self.contactChannelClient = [[ZNGContactChannelClient alloc] initWithSession:self serviceId:serviceId];
    self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
    dispatch_semaphore_signal(contactClientSemaphore);
    self.labelClient = [[ZNGLabelClient alloc] initWithSession:self serviceId:serviceId];
    self.eventClient = [[ZNGEventClient alloc] initWithSession:self serviceId:serviceId];
    self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
    
    [self _registerForPushNotificationsForServiceIds:@[serviceId] removePreviousSubscriptions:YES];
}

- (void) retrieveUserObject
{
    [self.userAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization * theUserAuthorization, ZNGStatus *status) {
        userAuthorization = theUserAuthorization;
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to retrieve current user info from the root URL: %@", error);
    }];
}

#pragma mark - Account retrieval
- (void) retrieveAvailableAccounts
{
    [self.accountClient getAccountListWithSuccess:^(NSArray *accounts, ZNGStatus *status) {
        
        if ([accounts count] == 0) {
            self.availableAccounts = @[];   // This ensures that we will set our list explicitly to an empty array instead of just nil if there is no data
        } else {
            self.availableAccounts = accounts;
        }
        
        // Clear our services since we may have just picked a new account.
        self.availableServices = nil;
        
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableAccounts = @[];
        self.availableServices = nil;
    }];
}

#pragma mark - Service retrieval
- (void) retrieveAvailableServices
{
    [self.serviceClient serviceListUnderAccountId:self.account.accountId success:^(NSArray *services, ZNGStatus *status) {
        if ([services count] == 0) {
            self.availableServices = @[];
        } else {
            self.availableServices = services;
        }
        
        if ([services count] == 1) {
            self.service = [services firstObject];
        }
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableServices = nil;
    }];
}

#pragma mark - Messaging
- (ZNGConversationServiceToContact *) conversationWithContact:(ZNGContact *)contact;
{
    // Do we have a cached version of this conversation already?
    ZNGConversationServiceToContact * conversation = self.conversationsByContactId[contact.contactId];
    
    if (conversation == nil) {
        conversation = [[ZNGConversationServiceToContact alloc] initFromService:self.service
                                                                      toContact:contact
                                                              withCurrentUserId:userAuthorization.userId
                                                                   usingChannel:nil
                                                              withMessageClient:self.messageClient
                                                                    eventClient:self.eventClient
                                                                  contactClient:self.contactClient];
        
        self.conversationsByContactId[contact.contactId] = conversation;
    }

    [conversation updateEvents];
    return conversation;
}

- (void) conversationWithContactId:(NSString *)contactId completion:(void (^)(ZNGConversationServiceToContact *))completion
{
    // Do we have a cached version of this conversation already?
    ZNGConversationServiceToContact * conversation = self.conversationsByContactId[contactId];
    
    if (conversation != nil) {
        completion(conversation);
        return;
    }
    
    void (^success)(ZNGContact *, ZNGStatus *) = ^(ZNGContact *contact, ZNGStatus *status) {
        if (contact == nil) {
            ZNGLogWarn(@"No contact could be retrieved with the ID of %@", contactId);
            return;
        }
        
        contact.contactClient = self.contactClient;
        ZNGConversationServiceToContact * conversation = [self conversationWithContact:contact];
        completion(conversation);
    };
    
    void (^failure)(ZNGError *) = ^(ZNGError *error) {
        ZNGLogWarn(@"Unable to retrieve contact with ID of %@.", contactId);
        completion(nil);
    };

    // If we have a contact client, full steam ahead
    if (self.contactClient != nil) {
        [self.contactClient contactWithId:contactId success:success failure:failure];
        return;
    }
    
    // We do not yet have a contact client.  Let's hang out and wait for one.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_time_t fiveSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
        long semaphoreValue = dispatch_semaphore_wait(contactClientSemaphore, fiveSeconds);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ((semaphoreValue) || (self.contactClient == nil)) {
                ZNGLogWarn(@"We waited for a contact client before attempting to retrieve contact data for contact #%@, but we never got a contact client :(", contactId);
                completion(nil);
                return;
            }
            
            [self.contactClient contactWithId:contactId success:success failure:failure];
        });
    });
}

- (ZNGServiceToContactViewController *) conversationViewControllerForConversation:(ZNGConversationServiceToContact *)conversation
{
    if (conversation == nil) {
        ZNGLogError(@"Attempted to display view controller for a nil conversation.");
        return nil;
    }
    
    ZNGServiceToContactViewController * vc = [[ZNGServiceToContactViewController alloc] init];
    vc.conversation = conversation;
    return vc;
}

- (void) sendMessage:(NSString *)body toContacts:(NSArray<ZNGContact *> *)contacts labels:(NSArray<ZNGLabel *> *)labels phoneNumbers:(NSArray<NSString *> *)phoneNumbers completion:(void (^_Nullable)(BOOL succeeded))completion
{
    NSUInteger typeCount = (BOOL)[contacts count] + (BOOL)[labels count] + (BOOL)[phoneNumbers count];
    
    if (typeCount == 0) {
        ZNGLogError(@"No recipients provided to sendMessage:.  Ignoring.");
        completion(NO);
        return;
    }
    
    // Since message PUT requires a recipient type for the entire message (contact vs. label,) we will have to send
    //  multiple messages if we have multiple recipient types.
    NSMutableArray<ZNGNewMessage *> * messages = [[NSMutableArray alloc] initWithCapacity:typeCount];
    
    if ([contacts count] > 0) {
        [messages addObject:[self _messageToContacts:contacts]];
    }
    
    if ([labels count] > 0) {
        [messages addObject:[self _messageToLabels:labels]];
    }
    
    if ([phoneNumbers count] > 0) {
        [messages addObject:[self _messageToPhoneNumbers:phoneNumbers]];
    }
    
    int64_t tenSeconds = 10 * NSEC_PER_SEC;
    
    // Loop through the sending of each message on a background thread, using a semaphore to wait for success between each message.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL failed = NO;

        for (ZNGNewMessage * message in messages) {
            message.body = body;
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.messageClient sendMessage:message success:^(ZNGNewMessageResponse *message, ZNGStatus *status) {
                    // This one sent.  Cool.
                    dispatch_semaphore_signal(semaphore);
                } failure:^(ZNGError *error) {
                    ZNGLogError(@"Failed to send message: %@", error);
                
                    failed = YES;
                    dispatch_semaphore_signal(semaphore);
                }];
            });
            
            NSDate * date = [NSDate date];
            dispatch_time_t tenSecondsFromNow = dispatch_time(DISPATCH_TIME_NOW, tenSeconds);
            long returnValue = dispatch_semaphore_wait(semaphore, tenSecondsFromNow);
            
            if (returnValue != 0) {
                ZNGLogError(@"Timed out after %.0f seconds waiting for response from message send.", [[NSDate date] timeIntervalSinceDate:date]);
                failed = YES;
            }
            
            if (failed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
                return;
            }
        }
        
        completion(YES);
    });
}

- (ZNGNewMessage *) _freshOutgoingMessage
{
    ZNGNewMessage * message = [[ZNGNewMessage alloc] init];
    
    ZNGChannelType * phoneNumberChannelType = [self.service phoneNumberChannelType];
    ZNGChannel * phoneNumberChannel = [self.service defaultPhoneNumberChannel];
    message.channelTypeIds = @[phoneNumberChannelType.channelTypeId];
    
    ZNGParticipant * sender = [[ZNGParticipant alloc] init];
    sender.participantId = self.service.serviceId;
    sender.channelValue = phoneNumberChannel.value;

    message.sender = sender;
    message.senderType = ZNGConversationParticipantTypeService;
    
    return message;
}

- (ZNGNewMessage *) _messageToContacts:(NSArray<ZNGContact *> *)contacts
{
    ZNGNewMessage * message = [self _freshOutgoingMessage];
    message.recipientType = ZNGConversationParticipantTypeContact;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[contacts count]];
    for (ZNGContact * contact in contacts) {
        ZNGChannel * channel = [contact defaultChannel] ?: [contact phoneNumberChannel];
        
        if (channel == nil) {
            ZNGLogError(@"Unable to find a default outgoing channel for %@ (%@).", [contact fullName], contact.contactId);
            continue;
        }
        
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.participantId = contact.contactId;
        recipient.channelValue = channel.value;
        
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

- (ZNGNewMessage *) _messageToLabels:(NSArray<ZNGLabel *> *)labels
{
    ZNGNewMessage * message = [self _freshOutgoingMessage];
    message.recipientType = ZNGConversationParticipantTypeLabel;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[labels count]];
    for (ZNGLabel * label in labels) {
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.participantId = label.labelId;
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

- (ZNGNewMessage *) _messageToPhoneNumbers:(NSArray<NSString *> *)phoneNumbers
{
    ZNGNewMessage * message = [self _freshOutgoingMessage];
    message.recipientType = ZNGConversationParticipantTypeContact;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[phoneNumbers count]];
    for (NSString * phoneNumber in phoneNumbers) {
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.channelValue = phoneNumber;
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

@end
