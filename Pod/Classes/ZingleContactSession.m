//
//  ZingleContactSession.m
//  Pods
//
//  Created by Jason Neel on 6/15/16.
//
//

#import "ZingleContactSession.h"
#import <AFNetworking/AFNetworking.h>
#import "ZNGLogging.h"
#import "ZNGContactClient.h"
#import "ZNGContactServiceClient.h"
#import "ZNGNotificationsClient.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGServiceClient.h"
#import "ZNGConversationViewController.h"
#import "ZNGConversationContactToService.h"
#import "ZNGContactToServiceViewController.h"

static const int zngLogLevel = ZNGLogLevelInfo;

// Override our read only array properties to get free KVO compliant setters
@interface ZingleContactSession ()
@property (nonatomic, strong, nullable) NSArray<ZNGContactService *> * availableContactServices;
@property (nonatomic, strong, nullable) ZNGConversationContactToService * conversation;
@property (nonatomic, strong, nullable) ZNGContact * contact;
@end

@implementation ZingleContactSession
{
    BOOL _onlyRegisterPushNotificationsForCurrentContactService;    // Flag that will be tied to support for multiple push notification registrations in the future
    
    dispatch_semaphore_t messageClientSemaphore;
    
    ZNGService * _service;   // Needed for creation of conversation view controller.  This may be unnecessary with a small refactor of that view.
}

- (instancetype) initWithToken:(NSString *)token
                           key:(NSString *)key
                 channelTypeId:(NSString *)channelTypeId
                  channelValue:(NSString *)channelValue
         contactServiceChooser:(nullable ZNGContactServiceChooser)contactServiceChooser
                  errorHandler:(nullable ZNGErrorHandler)errorHandler
{
    NSParameterAssert(channelTypeId);
    NSParameterAssert(channelValue);
    
    self = [super initWithToken:token key:key errorHandler:errorHandler];
    
    if (self != nil) {
        messageClientSemaphore = dispatch_semaphore_create(1);
        
        _channelTypeID = [channelTypeId copy];
        _channelValue = [channelValue copy];
        _onlyRegisterPushNotificationsForCurrentContactService = YES;
        self.contactServiceChooser = contactServiceChooser;
        
        // First we must populate our list of available contact services
        NSDictionary *parameters = @{ @"channel_value" : channelValue,
                                      @"channel_type_id" : channelTypeId };
        [self.contactServiceClient contactServiceListWithParameters:parameters success:^(NSArray *contactServices, ZNGStatus *status) {
            self.availableContactServices = contactServices;
            
            if (self.contactServiceChooser != nil) {
                self.contactServiceChooser(contactServices);
            }
        } failure:^(ZNGError *error) {
            ZNGLogInfo(@"Unable to find a contact service match for value \"%@\" of type \"%@\"", channelValue, channelTypeId);
        }];
    }
    
    return self;
}

- (void) setContactService:(ZNGContactService *)contactService
{
    ZNGContactService * selectedContactService = contactService;
    
    if ((![self.availableContactServices containsObject:selectedContactService]) && (selectedContactService != nil)) {
        ZNGLogError(@"Our %ld available contact services do not include the selection of %@", (unsigned long)[self.availableContactServices count], contactService);
        selectedContactService = nil;
    }
    
    // Make sure setting our contact service and wiping away any old contact happen atomically
    [self willChangeValueForKey:NSStringFromSelector(@selector(contactService))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(contact))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(conversation))];
    _contactService = selectedContactService;
    _contact = nil;
    _service = nil;
    [self setConversationForContactService];
    [self didChangeValueForKey:NSStringFromSelector(@selector(conversation))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contact))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contactService))];
    
    if (selectedContactService != nil) {
        [self initializeClients];
        [self findOrCreateContactForContactService];
    } else if (_onlyRegisterPushNotificationsForCurrentContactService) {
        // We are deselecting the current contact service and we are only maintaining push notifications for currently selected contact services.  We need to
        //  deregister for pushes.
        [self _unregisterForAllPushNotifications];
    }
}

- (void) setConversationForContactService
{
    // If we already have this conversation setup (which will happen if the contact service already contained a contact ID on selection,) do nothing
    if (self.conversation != nil) {
        ZNGLogDebug(@"Neglecting to create a conversation object because one already exists.");
        return;
    }
    
    if (self.contactService.contactId != nil) {
        
        void (^setupConversation)() = ^{
            self.conversation = [[ZNGConversationContactToService alloc] initFromContactChannelValue:self.channelValue
                                                                                       channelTypeId:self.channelTypeID
                                                                                           contactId:self.contactService.contactId
                                                                                    toContactService:self.contactService
                                                                                   withMessageClient:self.messageClient];
            [self.conversation updateMessages];
        };

        if (self.messageClient != nil) {
            ZNGLogDebug(@"Instantly creating conversation object.");
            setupConversation();
        } else {
            // We do not yet have a message client.  We will wait up to five seconds for the message client to be set and the semaphore to be signaled.
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                dispatch_time_t fiveSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
                long success = dispatch_semaphore_wait(messageClientSemaphore, fiveSeconds);
                
                if (success == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ZNGLogDebug(@"Creating conversation object after briefly waiting for a message client.");
                        setupConversation();
                    });
                } else {
                    ZNGLogError(@"No message client was ever created.  We are unable to setup our conversation object.");
                }
            });
        }

    } else {
        self.conversation = nil;
    }
}

- (void) initializeClients
{
    NSString * serviceId = self.contactService.serviceId;
    self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
    dispatch_semaphore_signal(messageClientSemaphore);
    self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
}

- (void) findOrCreateContactForContactService
{
    [self.contactClient findOrCreateContactWithChannelTypeID:_channelTypeID andChannelValue:_channelValue success:^(ZNGContact *contact, ZNGStatus *status) {
        if (contact == nil) {
            ZNGLogError(@"Unable to find nor create contact for value \"%@\" of channel type ID \"%@\".  Request returned no result.", _channelValue, _channelTypeID);
            return;
        }
        
        // We have a contact!  Now we need to set our header.
        contact.contactClient = self.contactClient;
        self.contact = contact;
        [self setAuthorizationHeader];
        
        // Set the conversation up if we did not do so already
        [self setConversationForContactService];
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to find nor create contact for value \"%@\" of channel type ID \"%@\".  Request failed.", _channelValue, _channelTypeID);
    }];
}

- (void) setAuthorizationHeader
{
    [self.userAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
        if (userAuthorization == nil) {
            ZNGLogError(@"Server did not respond with a user authorization object.");
            return;
        }
        
        if ([userAuthorization.authorizationClass isEqualToString:@"contact"]) {
            [self.sessionManager.requestSerializer setValue:self.contact.contactId forHTTPHeaderField:@"x-zingle-contact-id"];
        } else {
            ZNGLogWarn(@"User is of type \"%@,\" not contact.  Is the wrong type of session object being used?", userAuthorization.authorizationClass);
            [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"x-zingle-contact-id"];
        }
        
        [self registerForPushNotifications];
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to check user authorization status.");
    }];
}

- (void) registerForPushNotifications
{
    if (self.contactService.serviceId == nil) {
        ZNGLogWarn(@"Unable to register for push notifications with no selected contact service.");
        return;
    }
    
    NSArray * serviceIds = @[self.contactService.serviceId];
    [self _registerForPushNotificationsForServiceIds:serviceIds removePreviousSubscriptions:_onlyRegisterPushNotificationsForCurrentContactService];
}

#pragma mark - UI convenience
- (ZNGContactToServiceViewController *) conversationViewController
{
    if (_service == nil) {
        ZNGLogWarn(@"Unable to return conversation view controller.  There is no current conversation nor service.");
        return nil;
    }
    
    ZNGContactToServiceViewController * vc = [[ZNGContactToServiceViewController alloc] init];
    vc.conversation = self.conversation;
    return vc;
}

@end
