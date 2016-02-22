//
//  ZNGServiceClient.h
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGService.h"

@interface ZNGServiceClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)serviceListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* services, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure;

+ (void)serviceWithId:(NSString*)serviceId
              success:(void (^)(ZNGService* service, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)saveService:(ZNGService*)service
            success:(void (^)(ZNGService* service, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateServiceWithId:(NSString*)serviceId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGService* service, ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteServiceWithId:(NSString*)serviceId
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^)(ZNGError* error))failure;

@end
