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

@implementation ZingleContactSession
{
    void (^completion)(BOOL success, ZNGError * _Nullable error);
}

- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue completion:(nullable void (^)(BOOL success, ZNGError * _Nullable error))theCompletion
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        _channelTypeID = [channelTypeId copy];
        _channelValue = [channelValue copy];
        completion = [theCompletion copy];
        
        // First we must find our contact service
        NSDictionary *parameters = @{ @"channel_value" : channelValue,
                                      @"channel_type_id" : channelTypeId };
        [self.contactServiceClient contactServiceListWithParameters:parameters success:^(NSArray *contactServices, ZNGStatus *status) {
            if ([contactServices count] == 0) {
                ZNGLogInfo(@"Unable to find a contact service match for value \"%@\" of type \"%@\"", channelValue, channelTypeId);
                completion(NO, nil);
                completion = nil;
                return;
            }
            
            if ([contactServices count] > 1) {
                ZNGLogWarn(@"Found %lu matches for contact services with value \"%@\" of type \"%@\".  Using first match.",(unsigned long)[contactServices count], channelValue, channelTypeId);
            }
            
            _contactService = [contactServices firstObject];
            [self findOrCreateContactForContactService];
        } failure:^(ZNGError *error) {
            ZNGLogInfo(@"Unable to find a contact service match for value \"%@\" of type \"%@\"", channelValue, channelTypeId);
            completion(NO, error);
            completion = nil;
        }];
    }
    
    return self;
}

- (void) findOrCreateContactForContactService
{
    [self.contactClient findOrCreateContactWithChannelTypeID:_channelTypeID andChannelValue:_channelValue success:^(ZNGContact *contact, ZNGStatus *status) {
        if (contact == nil) {
            ZNGLogError(@"Unable to find nor create contact for value \"%@\" of channel type ID \"%@\".  Request returned no result.", _channelValue, _channelTypeID);
            completion(NO, nil);
            completion = nil;
            return;
        }
        
        // We have a contact!  Now we need to set our header.
        _contact = contact;
        [self setAuthorizationHeader];
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to find nor create contact for value \"%@\" of channel type ID \"%@\".  Request failed.", _channelValue, _channelTypeID);
        completion(NO, error);
        completion = nil;
    }];
}

- (void) setAuthorizationHeader
{
    [self.userAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
        if (userAuthorization == nil) {
            ZNGLogError(@"Server did not respond with a user authorization object.");
            completion(NO, nil);
            completion = nil;
            return;
        }
        
        if ([userAuthorization.authorizationClass isEqualToString:@"contact"]) {
            [self.sessionManager.requestSerializer setValue:self.contact.contactId forHTTPHeaderField:@"x-zingle-contact-id"];
        } else {
            ZNGLogWarn(@"User is of type \"%@,\" not contact.  Is the wrong type of session object being used?", userAuthorization.authorizationClass);
            [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"x-zingle-contact-id"];
        }
        
        // Job done!  We are ready to be used.  Use us.
        completion(YES, nil);
        completion = nil;
    } failure:^(ZNGError *error) {
        ZNGLogError(@"Unable to check user authorization status.");
        completion(NO, error);
        completion = nil;
    }];
}

@end
