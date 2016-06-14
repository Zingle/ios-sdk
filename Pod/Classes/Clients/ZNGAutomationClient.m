//
//  ZNGAutomationClient.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGAutomationClient.h"

@implementation ZNGAutomationClient

#pragma mark - GET methods

- (void)automationListWithParameters:(NSDictionary*)parameters
                             success:(void (^)(NSArray* automations, ZNGStatus* status))success
                             failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/automations", self.service.serviceId];
    
    [self getListWithParameters:parameters
                           path:path
                  responseClass:[ZNGAutomation class]
                        success:success
                        failure:failure];
}

- (void)automationWithId:(NSString*)automationId
                 success:(void (^)(ZNGAutomation* automation, ZNGStatus* status))success
                 failure:(void (^)(ZNGError* error))failure
{
    NSString * path = [NSString stringWithFormat:@"services/%@/automations/%@", self.service.serviceId, automationId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGAutomation class]
                      success:success
                      failure:failure];
}

#pragma mark - PUT methods

- (void)updateAutomation:(ZNGAutomation *)automation
          withParameters:(NSDictionary*)parameters
                 success:(void (^)(ZNGAutomation* automation, ZNGStatus* status))success
                 failure:(void (^)(ZNGError* error))failure
{
    NSString *path = [NSString stringWithFormat:@"services/%@/automations/%@", self.service.serviceId, automation.automationId];

    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGAutomation class]
              success:success
              failure:failure];
}

@end
