//
//  ZNGAutomationClient.h
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGAutomation.h"

@class ZNGAutomation;

@interface ZNGAutomationClient : ZNGBaseClientService

#pragma mark - GET methods

- (void)automationListWithParameters:(NSDictionary*)parameters
                             success:(void (^)(NSArray* automations, ZNGStatus* status))success
                             failure:(void (^)(ZNGError* error))failure;

- (void)automationWithId:(NSString*)automationId
                 success:(void (^)(ZNGAutomation* automation, ZNGStatus* status))success
                 failure:(void (^)(ZNGError* error))failure;


#pragma mark - PUT methods

- (void)updateAutomation:(ZNGAutomation *)automation
          withParameters:(NSDictionary*)parameters
                 success:(void (^)(ZNGAutomation* automation, ZNGStatus* status))success
                 failure:(void (^)(ZNGError* error))failure;

@end
