//
//  ZNGContactFieldClient.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGContactField.h"

@interface ZNGContactFieldClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)contactFieldListWithParameters:(NSDictionary*)parameters
                         withServiceId:(NSString *)serviceId
                               success:(void (^)(NSArray* contactFields, ZNGStatus* status))success
                               failure:(void (^)(ZNGError* error))failure;

+ (void)contactFieldWithId:(NSString*)contactFieldId
             withServiceId:(NSString *)serviceId
                   success:(void (^)(ZNGContactField* contactField, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)saveContactField:(ZNGContactField*)contactField
           withServiceId:(NSString *)serviceId
                 success:(void (^)(ZNGContactField* contactField, ZNGStatus* status))success
                 failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateContactFieldWithId:(NSString*)contactFieldId
                   withServiceId:(NSString *)serviceId
                  withParameters:(NSDictionary*)parameters
                         success:(void (^)(ZNGContactField* contactField, ZNGStatus* status))success
                         failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteContactFieldWithId:(NSString*)contactFieldId
                   withServiceId:(NSString *)serviceId
                         success:(void (^)(ZNGStatus* status))success
                         failure:(void (^)(ZNGError* error))failure;

@end
