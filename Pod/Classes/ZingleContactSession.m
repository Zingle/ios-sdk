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
#import "ZNGUserAuthorizationClient.h"

static const int zngLogLevel = ZNGLogLevelInfo;

// Override our read only contact service array property to get a free KVO compliant setter
@interface ZingleContactSession ()
@property (nonatomic, strong, nullable) NSArray<ZNGContactService *> * availableContactServices;
@end

@implementation ZingleContactSession

- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue contactServiceChooser:(ZNGContactServiceChooser)contactServiceChooser
{
    NSParameterAssert(channelTypeId);
    NSParameterAssert(channelValue);
    
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        _channelTypeID = [channelTypeId copy];
        _channelValue = [channelValue copy];
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
    _contactService = selectedContactService;
    _contact = nil;
    [self didChangeValueForKey:NSStringFromSelector(@selector(contact))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(contactService))];
    
    if (selectedContactService != nil) {
        [self findOrCreateContactForContactService];
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
        _contact = contact;
        [self setAuthorizationHeader];
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
        
        // Job done!  We are ready to be used.  Use us.
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to check user authorization status.");
    }];
}

@end
