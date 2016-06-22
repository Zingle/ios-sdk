//
//  ZNGContactClient.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGContactClient.h"
#import "ZNGNewContact.h"

@implementation ZNGContactClient

#pragma mark - GET methods

- (void)contactListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* contacts, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts", self.serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGContact class]
                        success:success
                        failure:failure];
}

- (void)contactWithId:(NSString*)contactId
              success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@", self.serviceId, contactId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGContact class]
                      success:success
                      failure:failure];
}

- (void)findOrCreateContactWithChannelTypeID:(NSString *)channelTypeId
                             andChannelValue:(NSString *)channelValue
                                     success:(void (^) (ZNGContact *contact, ZNGStatus* status))success
                                     failure:(void (^) (ZNGError *error))failure
{
    NSDictionary *channels = @{ @"value" : channelValue,
                                @"channel_type_id" : channelTypeId };
    NSDictionary *params = @{ @"channels" : @[ channels ]};
    
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts?return_existing=1", self.serviceId];
    
    [self postWithParameters:params
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

#pragma mark - POST methods

- (void)saveContact:(ZNGContact*)contact
            success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    ZNGNewContact* newContact = [[ZNGNewContact alloc] initWithContact:contact];
    
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts", self.serviceId];
    
    [self postWithModel:newContact
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

- (void)updateContactFieldValue:(ZNGNewContactFieldValue*)contactFieldValue
             withContactFieldId:(NSString*)contactFieldId
                  withContactId:(NSString*)contactId
                        success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/custom-field-values/%@", self.serviceId, contactId, contactFieldId];
    
    [self postWithModel:contactFieldValue
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

- (void)triggerAutomationWithId:(NSString*)automationId
                  withContactId:(NSString*)contactId
                        success:(void (^)(ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/automations/%@", self.serviceId, contactId, automationId];
    
    [self postWithModel:nil
                   path:path
          responseClass:nil
                success:^(id responseObject, ZNGStatus *status) {
                    success(status);
                } failure:failure];
}

- (void)addLabelWithId:(NSString*)labelId
         withContactId:(NSString*)contactId
               success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/labels/%@", self.serviceId, contactId, labelId];
    
    [self postWithModel:nil
                   path:path
          responseClass:[ZNGContact class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

- (void)updateContactWithId:(NSString*)contactId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@", self.serviceId, contactId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGContact class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

- (void)deleteContactWithId:(NSString*)contactId
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@", self.serviceId, contactId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

- (void)removeLabelWithId:(NSString*)labelId
            withContactId:(NSString*)contactId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/contacts/%@/labels/%@", self.serviceId, contactId, labelId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
