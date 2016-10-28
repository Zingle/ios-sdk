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
#import "ZNGEventClient.h"
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
    
    dispatch_semaphore_t messageAndEventClientSemaphore;
    dispatch_semaphore_t userHeaderSetSemaphore;
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
        messageAndEventClientSemaphore = dispatch_semaphore_create(0);
        userHeaderSetSemaphore = dispatch_semaphore_create(0);
        
        _channelTypeID = [channelTypeId copy];
        _channelValue = [channelValue copy];
        _onlyRegisterPushNotificationsForCurrentContactService = YES;
        self.contactServiceChooser = contactServiceChooser;
    }
    
    return self;
}

- (void) connect
{
    // First we must populate our list of available contact services
    NSDictionary *parameters = @{ @"channel_value" : self.channelValue,
                                  @"channel_type_id" : self.channelTypeID };
    [self.contactServiceClient contactServiceListWithParameters:parameters success:^(NSArray *contactServices, ZNGStatus *status) {
        self.availableContactServices = contactServices;
        
        if (self.contactServiceChooser != nil) {
            self.contactService = self.contactServiceChooser(contactServices);
        }
    } failure:^(ZNGError *error) {
        ZNGLogInfo(@"Unable to find a contact service match for value \"%@\" of type \"%@\"", self.channelValue, self.channelTypeID);
    }];
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
    if (self.contact.contactId != nil) {
        _conversation = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            dispatch_time_t fiveSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
            
            long success = dispatch_semaphore_wait(messageAndEventClientSemaphore, fiveSeconds);
            
            if (success == 0) {
                success = dispatch_semaphore_wait(userHeaderSetSemaphore, fiveSeconds);
            }
            
            if (success == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ZNGLogDebug(@"Creating conversation object.");
                    self.conversation = [[ZNGConversationContactToService alloc] initFromContactChannelValue:self.channelValue
                                                                                               channelTypeId:self.channelTypeID
                                                                                                   contactId:self.contact.contactId
                                                                                            toContactService:self.contactService
                                                                                           withMessageClient:self.messageClient
                                                                                                 eventClient:self.eventClient];
                    [self.conversation loadRecentEventsErasingOlderData:NO];
                    
                    self.available = YES;
                });
            } else {
                ZNGLogError(@"No message client was ever created.  We are unable to setup our conversation object.");
            }
        });

    } else {
        self.conversation = nil;
    }
}

- (void) initializeClients
{
    NSString * serviceId = self.contactService.serviceId;
    self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
    self.eventClient = [[ZNGEventClient alloc] initWithSession:self serviceId:serviceId];
    dispatch_semaphore_signal(messageAndEventClientSemaphore);
    
    // Prevent overwriting a contact client to facilitate some testing via dependency injection
    if ((self.contactClient == nil) || (![self.contactClient.serviceId isEqualToString:serviceId])) {
        self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
    }
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

- (void) retrieveServiceObject
{
    if ([self.contactService.serviceId length] == 0) {
        ZNGLogWarn(@"retrieveServiceObject was called, but we do not have a service ID in our %@ contact service", self.contactService.serviceDisplayName);
        return;
    }
    
    [self.serviceClient serviceWithId:self.contactService.serviceId success:^(ZNGService *service, ZNGStatus *status) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
        _service = service;
        [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
        
        [self ensureContactHasAllDefaultCustomFields];
        
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to retrieve %@ service: %@", self.contactService.serviceId, error);
    }];
}

- (void) ensureContactHasAllDefaultCustomFields
{
    NSMutableArray<NSString *> * defaultCustomFieldDisplayNames = [[self _defaultCustomFieldDisplayNames] mutableCopy];

    // Remove any defaults that this dude already has
    for (ZNGContactFieldValue * existingCustomFieldValue in self.contact.customFieldValues) {
        [defaultCustomFieldDisplayNames removeObject:existingCustomFieldValue.customField.displayName];
    }
    
    NSUInteger defaultCount = [defaultCustomFieldDisplayNames count];
    
    if (defaultCount == 0) {
        // There are no missing defaults
        return;
    }
    
    NSMutableArray<ZNGContactField *> * defaultCustomFields = [[NSMutableArray alloc] initWithCapacity:defaultCount];
    
    // Build our array of missing default custom fields
    for (NSString * defaultName in defaultCustomFieldDisplayNames) {
        for (ZNGContactField * customField in self.service.contactCustomFields) {
            if ([customField.displayName isEqualToString:defaultName]) {
                [defaultCustomFields addObject:customField];
                break;
            }
        }
    }
    
    if ([defaultCustomFields count] < defaultCount) {
        ZNGLogWarn(@"%llu default custom field names were listed, but only %llu were found in the service object.", (unsigned long long)defaultCount, (unsigned long long)[defaultCustomFields count]);
    }
    
    // Build our array of custom field values for all of the missing custom fields
    NSMutableArray<ZNGContactFieldValue *> * newCustomFieldValues = (self.contact.customFieldValues != nil) ? [self.contact.customFieldValues mutableCopy] : [[NSMutableArray alloc] init];
    
    for (ZNGContactField * customField in defaultCustomFields) {
        ZNGContactFieldValue * customFieldValue = [[ZNGContactFieldValue alloc] init];
        customFieldValue.customField = customField;
        [newCustomFieldValues addObject:customFieldValue];
    }
    
    self.contact.customFieldValues = newCustomFieldValues;
}

- (NSArray<NSString *> *) _defaultCustomFieldDisplayNames
{
    return @[@"Title", @"First Name", @"Last Name"];
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
        
        [self retrieveServiceObject];
        [self registerForPushNotifications];
        
        dispatch_semaphore_signal(userHeaderSetSemaphore);
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to check user authorization status.");
        
        // Even though we failed, we will still signal the semaphore since we never expect to recover while anyone is waiting on it
        dispatch_semaphore_signal(userHeaderSetSemaphore);
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
    ZNGContactToServiceViewController * vc = [[ZNGContactToServiceViewController alloc] init];
    vc.conversation = self.conversation;
    return vc;
}

@end
