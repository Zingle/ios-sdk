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

+ (void)contactListWithServiceId:(NSString*)serviceId
                      parameters:(NSDictionary*)parameters
                         success:(void (^)(NSArray* contacts))success
                         failure:(void (^)(ZNGError* error))failure {
  NSString* path =
      [NSString stringWithFormat:@"services/%@/contacts", serviceId];
      
  [self getListWithParameters:parameters
                         path:path
                responseClass:[ZNGContact class]
                      success:success
                      failure:failure];
}

+ (void)contactWithId:(NSString*)contactId
        withServiceId:(NSString*)serviceId
              success:(void (^)(ZNGContact* contact))success
              failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/contacts/%@", serviceId, contactId];
      
  [self getWithResourcePath:path
              responseClass:[ZNGContact class]
                    success:success
                    failure:failure];
}

#pragma mark - POST methods

+ (void)saveContact:(ZNGContact*)contact
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGContact* contact))success
            failure:(void (^)(ZNGError* error))failure {
  ZNGNewContact* newContact = [[ZNGNewContact alloc] initWithContact:contact];
  
  NSString* path =
      [NSString stringWithFormat:@"services/%@/contacts", serviceId];
      
  [self postWithModel:newContact
                 path:path
        responseClass:[ZNGContact class]
              success:success
              failure:failure];
}

+ (void)updateContactCustomFieldValue:
            (ZNGCustomFieldValue*)contactCustomFieldValue
                    withCustomFieldId:(NSString*)customFieldId
                        withContactId:(NSString*)contactId
                        withServiceId:(NSString*)serviceId
                              success:(void (^)(ZNGContact* contact))success
                              failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/contacts/%@/custom-field-values/%@",
                       serviceId, contactId, customFieldId];
                       
  [self postWithModel:contactCustomFieldValue
                 path:path
        responseClass:[ZNGContact class]
              success:success
              failure:failure];
}

+ (void)triggerAutomationWithId:(NSString*)automationId
                  withContactId:(NSString*)contactId
                  withServiceId:(NSString*)serviceId
                        success:(void (^)(ZNGContact* contact))success
                        failure:(void (^)(ZNGError* error))failure {
  NSString* path =
      [NSString stringWithFormat:@"services/%@/contacts/%@/automations/%@",
                                 serviceId, contactId, automationId];
                                 
  [self postWithModel:nil
                 path:path
        responseClass:nil
              success:success
              failure:failure];
}

+ (void)addLabelWithId:(NSString*)labelId
         withContactId:(NSString*)contactId
         withServiceId:(NSString*)serviceId
               success:(void (^)(ZNGContact* contact))success
               failure:(void (^)(ZNGError* error))failure {
  NSString* path =
      [NSString stringWithFormat:@"services/%@/contacts/%@/labels/%@",
                                 serviceId, contactId, labelId];
                                 
  [self postWithModel:nil
                 path:path
        responseClass:nil
              success:success
              failure:failure];
}

#pragma mark - PUT methods

+ (void)updateContactWithId:(NSString*)contactId
              withServiceId:(NSString*)serviceId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGContact* contact))success
                    failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/contacts/%@", serviceId, contactId];
      
  [self putWithPath:path
         parameters:parameters
      responseClass:[ZNGContact class]
            success:success
            failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteContactWithId:(NSString*)contactId
              withServiceId:(NSString*)serviceId
                    success:(void (^)())success
                    failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/contacts/%@", serviceId, contactId];
      
  [self deleteWithPath:path success:success failure:failure];
}

+ (void)removeLabelWithId:(NSString*)labelId
            withContactId:(NSString*)contactId
            withServiceId:(NSString*)serviceId
                  success:(void (^)(ZNGContact* contact))success
                  failure:(void (^)(ZNGError* error))failure {
  NSString* path =
      [NSString stringWithFormat:@"services/%@/contacts/%@/labels/%@",
                                 serviceId, contactId, labelId];
                                 
  [self deleteWithPath:path success:success failure:failure];
}

@end
