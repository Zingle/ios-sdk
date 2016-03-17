//
//  ZNGContactClient.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGContact.h"
#import "ZNGContactFieldValue.h"

@interface ZNGContactClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)contactListWithParameters:(NSDictionary *)parameters
                          success:(void (^)(NSArray* contacts, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;

+ (void)contactListWithServiceId:(NSString*)serviceId
                      parameters:(NSDictionary*)parameters
                         success:(void (^)(NSArray* contacts, ZNGStatus* status))success
                         failure:(void (^)(ZNGError* error))failure;

+ (void)contactWithId:(NSString*)contactId
        withServiceId:(NSString*)serviceId
              success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;

+ (void)findOrCreateContactWithChannelTypeID:(NSString *)channelTypeId
                             andChannelValue:(NSString *)channelValue
                               withServiceId:(NSString *)serviceId
                                     success:(void (^) (ZNGContact *contact, ZNGStatus* status))success
                                     failure:(void (^) (ZNGError *error))failure;

#pragma mark - POST methods

+ (void)saveContact:(ZNGContact*)contact
      withServiceId:(NSString*)serviceId
            success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

+ (void)updateContactFieldValue:(ZNGContactFieldValue*)contactFieldValue
             withContactFieldId:(NSString*)contactFieldId
                  withContactId:(NSString*)contactId
                  withServiceId:(NSString*)serviceId
                        success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

+ (void)triggerAutomationWithId:(NSString*)automationId
                  withContactId:(NSString*)contactId
                  withServiceId:(NSString*)serviceId
                        success:(void (^)(ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

+ (void)addLabelWithId:(NSString*)labelId
         withContactId:(NSString*)contactId
         withServiceId:(NSString*)serviceId
               success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateContactWithId:(NSString*)contactId
              withServiceId:(NSString*)serviceId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteContactWithId:(NSString*)contactId
              withServiceId:(NSString*)serviceId
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

+ (void)removeLabelWithId:(NSString*)labelId
            withContactId:(NSString*)contactId
            withServiceId:(NSString*)serviceId
                  success:(void (^)(ZNGStatus* status))success
                  failure:(void (^)(ZNGError* error))failure;

@end
