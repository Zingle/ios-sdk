//
//  ZNGTemplateClient.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGTemplate.h"

@interface ZNGTemplateClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)templateListWithParameters:(NSDictionary*)parameters
                     withServiceId:(NSString *)serviceId
                           success:(void (^)(NSArray* templ, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

+ (void)templateWithId:(NSString*)templateId
         withServiceId:(NSString *)serviceId
               success:(void (^)(ZNGTemplate* templ, ZNGStatus* status))success
               failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)saveTemplate:(ZNGTemplate*)templ
       withServiceId:(NSString *)serviceId
             success:(void (^)(ZNGTemplate* templ, ZNGStatus* status))success
             failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateTemplateWithId:(NSString*)templateId
               withServiceId:(NSString *)serviceId
              withParameters:(NSDictionary*)parameters
                     success:(void (^)(ZNGTemplate* templ, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteTemplateWithId:(NSString*)templateId
               withServiceId:(NSString *)serviceId
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure;

@end
