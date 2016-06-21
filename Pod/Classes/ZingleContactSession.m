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

static const int zngLogLevel = ZNGLogLevelInfo;

// Override our read only array properties to get free KVO compliant setters
@interface ZingleContactSession ()
@property (nonatomic, strong, nullable) NSArray<ZNGContactService *> * availableContactServices;
@property (nonatomic, strong, nullable) ZNGConversation * conversation;
@property (nonatomic, strong, nullable) ZNGContact * contact;
@end

@implementation ZingleContactSession
{
    BOOL _onlyRegisterPushNotificationsForCurrentContactService;    // Flag that will be tied to support for multiple push notification registrations in the future
    
    ZNGService * _service;   // Needed for creation of conversation view controller.  This may be unnecessary with a small refactor of that view.
}

- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue contactServiceChooser:(ZNGContactServiceChooser)contactServiceChooser
{
    NSParameterAssert(channelTypeId);
    NSParameterAssert(channelValue);
    
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
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
    _conversation = nil;
    _service = nil;
    [self didChangeValueForKey:NSStringFromSelector(@selector(conversation))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contact))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contactService))];
    
    if (selectedContactService != nil) {
        [self findOrCreateContactForContactService];
        [self findChannelTypeAndSetupConversation];
    } else if (_onlyRegisterPushNotificationsForCurrentContactService) {
        // We are deselecting the current contact service and we are only maintaining push notifications for currently selected contact services.  We need to
        //  deregister for pushes.
        [self _unregisterForAllPushNotifications];
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
        self.contact = contact;
        [self setAuthorizationHeader];
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to find nor create contact for value \"%@\" of channel type ID \"%@\".  Request failed.", _channelValue, _channelTypeID);
    }];
}

- (void) findChannelTypeAndSetupConversation
{
    NSString * serviceId = self.contactService.serviceId;
    
    if (serviceId == nil) {
        return;
    }
    
    [self.serviceClient serviceWithId:serviceId success:^(ZNGService *service, ZNGStatus *status) {
        
        _service = service;
        ZNGChannel * serviceChannel = nil;
        
        for (ZNGChannel * channel in service.channels) {
            if (channel.channelType.channelTypeId == self.channelTypeID) {
                serviceChannel = channel;
                break;
            }
        }
        
        if (serviceChannel == nil) {
            ZNGLogError(@"Unable to find channel type ID %@ in the current service and its %lu channels", self.channelTypeID, (unsigned long)[service.channels count]);
            return;
        }
        
        ZNGConversation * conversation = [[ZNGConversation alloc] init];
        conversation.session = self;
        conversation.contact = self.contact;
        conversation.channelType = serviceChannel.channelType;
        conversation.contactChannelValue = self.channelValue;
        conversation.serviceChannelValue = serviceChannel.value;
        conversation.serviceId = self.contactService.serviceId;
        conversation.contactId = self.contact.contactId;
        
        [conversation updateMessages];
        
        self.conversation = conversation;
        
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to find service with ID of %@.  Messaging will fail forever.", serviceId);
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
- (ZNGConversationViewController *) conversationViewController
{
    if (_service == nil) {
        ZNGLogWarn(@"Unable to return conversation view controller.  There is no current conversation nor service.");
        return nil;
    }
    
    ZNGConversationViewController * vc = [[ZNGConversationViewController alloc] init];
    vc.conversation = self.conversation;
    return vc;
}

@end
