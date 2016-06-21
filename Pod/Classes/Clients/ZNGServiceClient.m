//
//  ZNGServiceClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGServiceClient.h"
#import "ZNGNewService.h"

@implementation ZNGServiceClient

#pragma mark - GET methods

- (void)serviceListWithSuccess:(void (^)(NSArray* services, ZNGStatus* status))success
                       failure:(void (^)(ZNGError* error))failure
{
    [self serviceListUnderAccountId:nil success:success failure:failure];
}

- (void) serviceListUnderAccountId:(NSString *)accountId
                           success:(void (^)(NSArray* services, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSDictionary * parameters = nil;
    
    if (accountId != nil) {
        parameters = @{ @"account_id" : accountId };
    }
    
    [self getListWithParameters:parameters path:@"services" responseClass:[ZNGService class] success:success failure:failure];
}

- (void)serviceListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* services, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure
{
    [self getListWithParameters:parameters
                           path:@"services"
                  responseClass:[ZNGService class]
                        success:success
                        failure:failure];
}

- (void)serviceWithId:(NSString*)serviceId
              success:(void (^)(ZNGService* service, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@", serviceId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGService class]
                      success:success
                      failure:failure];
}

@end
