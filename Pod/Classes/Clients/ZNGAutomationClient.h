//
//  ZNGAutomationClient.h
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGAutomation.h"

@interface ZNGAutomationClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)automationListWithParameters:(NSDictionary*)parameters
                       withServiceId:(NSString *)serviceId
                             success:(void (^)(NSArray* automations))success
                             failure:(void (^)(ZNGError* error))failure;

+ (void)automationWithId:(NSString*)automationId
           withServiceId:(NSString *)serviceId
                 success:(void (^)(ZNGAutomation* automation))success
                 failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateAutomationWithId:(NSString*)automationId
                 withServiceId:(NSString *)serviceId
                withParameters:(NSDictionary*)parameters
                       success:(void (^)(ZNGAutomation* automation))success
                       failure:(void (^)(ZNGError* error))failure;

@end
