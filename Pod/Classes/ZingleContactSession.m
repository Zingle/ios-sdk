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
#import "ZNGSocketClient.h"

static const int zngLogLevel = ZNGLogLevelDebug;

// Override our read only array properties to get free KVO compliant setters
@interface ZingleContactSession ()
@property (nonatomic, strong, nullable) NSArray<ZNGContactService *> * availableContactServices;
@property (nonatomic, strong, nullable) ZNGConversationContactToService * conversation;
@property (nonatomic, strong, nullable) ZNGContact * contact;
@property (nonatomic, strong, nullable) ZNGService * service;
@end

@implementation ZingleContactSession
{
    BOOL _onlyRegisterPushNotificationsForCurrentContactService;    // Flag that will be tied to support for multiple push notification registrations in the future
    
    NSDate * serviceUpdateTime;
}

- (instancetype) initWithToken:(NSString *)token
                           key:(NSString *)key
                 channelTypeId:(NSString *)channelTypeId
                  channelValue:(NSString *)channelValue
{
    NSParameterAssert(channelTypeId);
    NSParameterAssert(channelValue);
    
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        _channelTypeID = [channelTypeId copy];
        _channelValue = [channelValue copy];
        _onlyRegisterPushNotificationsForCurrentContactService = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyReturnedFromBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyContactSessionPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) connect
{
    [self connectWithContactServiceChooser:nil completion:nil];
}

- (void) connectWithContactServiceChooser:(nullable ZNGContactServiceChooser)contactServiceChooser completion:(nullable ZNGContactSessionCallback)completion
{
    if (contactServiceChooser != nil) {
        self.contactServiceChooser = contactServiceChooser;
    }
    
    if (completion != nil) {
        self.completion = completion;
    }
    
    // First we must populate our list of available contact services
    NSDictionary *parameters = @{ @"channel_value" : self.channelValue,
                                  @"channel_type_id" : self.channelTypeID };
    [self.contactServiceClient contactServiceListWithParameters:parameters success:^(NSArray *contactServices, ZNGStatus *status) {
        self.availableContactServices = contactServices;
        
        if (self.contactServiceChooser != nil) {
            self.contactService = self.contactServiceChooser(contactServices);
        }
    } failure:^(ZNGError *error) {
        self.mostRecentError = error;
        ZNGLogInfo(@"Unable to find a contact service match for value \"%@\" of type \"%@\"", self.channelValue, self.channelTypeID);
    }];
}

- (void) setService:(ZNGService *)service
{
    _service = service;
    serviceUpdateTime = [NSDate date];
}

- (void) notifyReturnedFromBackground:(NSNotification *)notification
{
    [self updateServiceIfOldData];
}

- (void) notifyContactSessionPushNotificationReceived:(NSNotification *)notification
{
    // We only care about push notifications that specify our current service ID
    NSString * serviceId = notification.userInfo[@"aps"][@"service"];
    
    if ([serviceId isEqualToString:self.contactService.serviceId]) {
        [self updateCurrentService];
    }
}

/**
 *  Refreshes our current service object if the data is older than ten minutes old.
 */
- (void) updateServiceIfOldData
{
    if (self.service == nil) {
        return;
    }
    
    BOOL shouldRefresh = NO;
    
    if (serviceUpdateTime == nil) {
        ZNGLogError(@"Our service object is set, but we do not have a timestamp of our last update.  Refreshing.");
        shouldRefresh = YES;
    } else {
        NSTimeInterval timeSinceUpdate = [[NSDate date] timeIntervalSinceDate:serviceUpdateTime];
        NSTimeInterval tenMinutes = (10.0 * 60.0);
        shouldRefresh = (timeSinceUpdate > tenMinutes);
    }
    
    if (shouldRefresh) {
        [self updateCurrentService];
    }
}

- (void) updateCurrentService
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self synchronouslyRetrieveServiceObject];
    });
}

- (void) setContactService:(ZNGContactService *)contactService
{
    [self setContactService:contactService completion:nil];
}

- (void) setContactService:(ZNGContactService *)contactService completion:(ZNGContactSessionCallback)completion
{
    if (completion != nil) {
        self.completion = completion;
    }
    
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
    serviceUpdateTime = nil;
    _conversation = nil;
    [self didChangeValueForKey:NSStringFromSelector(@selector(conversation))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contact))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contactService))];
    
    if (selectedContactService != nil) {
        [self initializeClients];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self synchronouslyFindOrCreateContact];
            [self synchronouslySetAuthorizationHeader];
            [self connectSocket];
            [self registerForPushNotifications];    // Note that we are waiting to register for pushes until after we get our contact object and set our auth header as a contact.
            [self synchronouslyRetrieveServiceObject];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self ensureContactHasAllDefaultCustomFields];
                [self setConversationForContactService];
                
                if (self.conversation != nil) {
                    self.available = YES;
                    
                    if (self.completion != nil) {
                        self.completion(self.contactService, self.service, nil);
                        self.completion = nil;
                    }
                } else {
                    ZNGLogWarn(@"Initialization failed.  Unable to create conversation.");
                    
                    if (self.completion != nil) {
                        self.completion(nil, nil, self.mostRecentError);
                        self.completion = nil;
                    }
                }
            });
        });

    } else if (_onlyRegisterPushNotificationsForCurrentContactService) {
        // We are deselecting the current contact service and we are only maintaining push notifications for currently selected contact services.  We need to
        //  deregister for pushes.
        [self _unregisterForAllPushNotifications];
    }
}

- (void) setConversationForContactService
{
    if (self.contact.contactId != nil) {
        ZNGLogDebug(@"Creating conversation object.");
        self.conversation = [[ZNGConversationContactToService alloc] initFromContactChannelValue:self.channelValue
                                                                                   channelTypeId:self.channelTypeID
                                                                                       contactId:self.contact.contactId
                                                                                toContactService:self.contactService
                                                                               withMessageClient:self.messageClient
                                                                                     eventClient:self.eventClient];
        [self.conversation loadRecentEventsErasingOlderData:NO];

    } else {
        self.conversation = nil;
    }
}

- (void) initializeClients
{
    NSString * serviceId = self.contactService.serviceId;
    self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
    self.eventClient = [[ZNGEventClient alloc] initWithSession:self serviceId:serviceId];
    
    // Prevent overwriting a contact client to facilitate some testing via dependency injection
    if ((self.contactClient == nil) || (![self.contactClient.serviceId isEqualToString:serviceId])) {
        self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
    }
}

- (void) synchronouslyFindOrCreateContact
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.contactClient findOrCreateContactWithChannelTypeID:_channelTypeID andChannelValue:_channelValue success:^(ZNGContact *contact, ZNGStatus *status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            contact.contactClient = self.contactClient;
            self.contact = contact;
            dispatch_semaphore_signal(semaphore);
        });
        
    } failure:^(ZNGError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mostRecentError = error;
            ZNGLogError(@"Unable to find nor create contact for value \"%@\" of channel type ID \"%@\".  Request failed.", _channelValue, _channelTypeID);
            dispatch_semaphore_signal(semaphore);
        });
    }];
    
    dispatch_time_t tenSecondsFromNow = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));
    long timedOut = dispatch_semaphore_wait(semaphore, tenSecondsFromNow);
    
    if (timedOut) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ZNGLogError(@"Timed out waiting for findOrcreateContactWithChannelTypeID:");
            ZNGError * error = [ZNGError errorWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Timed out waiting for find or create contact request response semaphore" }];
            self.mostRecentError = error;
        });
    }
}

- (void) synchronouslyRetrieveServiceObject
{
    if ([self.contactService.serviceId length] == 0) {
        ZNGLogWarn(@"retrieveServiceObject was called, but we do not have a service ID in our %@ contact service", self.contactService.serviceDisplayName);
        return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.serviceClient serviceWithId:self.contactService.serviceId success:^(ZNGService *service, ZNGStatus *status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.service = service;
            dispatch_semaphore_signal(semaphore);
        });
        
    } failure:^(ZNGError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mostRecentError = error;
            ZNGLogError(@"Unable to retrieve %@ service: %@", self.contactService.serviceId, error);
            dispatch_semaphore_signal(semaphore);
        });
    }];
    
    dispatch_time_t tenSecondsFromNow = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));
    long timedOut = dispatch_semaphore_wait(semaphore, tenSecondsFromNow);
    
    if (timedOut) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ZNGLogError(@"Timed out waiting for GET service object response");
            ZNGError * error = [ZNGError errorWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Timed out waiting for a service object GET response" }];
            self.mostRecentError = error;
        });
    }
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

- (void) synchronouslySetAuthorizationHeader
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.userAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (userAuthorization == nil) {
                ZNGLogError(@"Server did not respond with a user authorization object.");
                ZNGError * error = [ZNGError errorWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"Server did not respond with a user authorization object" }];
                self.mostRecentError = error;
                dispatch_semaphore_signal(semaphore);
                return;
            }
            
            if ([userAuthorization.authorizationClass isEqualToString:@"contact"]) {
                [self.sessionManager.requestSerializer setValue:self.contact.contactId forHTTPHeaderField:@"x-zingle-contact-id"];
            } else {
                ZNGLogWarn(@"User is of type \"%@,\" not contact.  Is the wrong type of session object being used?", userAuthorization.authorizationClass);
                [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"x-zingle-contact-id"];
            }
        
            dispatch_semaphore_signal(semaphore);
            
        });
    } failure:^(ZNGError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mostRecentError = error;
            ZNGLogError(@"Unable to check user authorization status: %@", error);
            dispatch_semaphore_signal(semaphore);
        });
    }];
    
    dispatch_time_t tenSecondsFromNow = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));
    long timedOut = dispatch_semaphore_wait(semaphore, tenSecondsFromNow);
    
    if (timedOut) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ZNGLogError(@"Timed out waiting for user auth header");
            ZNGError * error = [ZNGError errorWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Timed out waiting for user authorization response semaphore" }];
            self.mostRecentError = error;
        });
    }
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

- (void) connectSocket
{
    self.socketClient = [[ZNGSocketClient alloc] initWithSession:self];
    [self.socketClient connect];
}

#pragma mark - UI convenience
- (ZNGContactToServiceViewController *) conversationViewController
{
    ZNGContactToServiceViewController * vc = [[ZNGContactToServiceViewController alloc] init];
    vc.conversation = self.conversation;
    return vc;
}

@end
