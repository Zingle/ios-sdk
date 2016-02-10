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

+ (void)serviceListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* services))success
                          failure:(void (^)(ZNGError* error))failure {
  [self getListWithParameters:parameters
                         path:@"services"
                responseClass:[ZNGService class]
                      success:success
                      failure:failure];
}

+ (void)serviceWithId:(NSString*)serviceId
              success:(void (^)(ZNGService* service))success
              failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString stringWithFormat:@"services/%@", serviceId];
  
  [self getWithResourcePath:path
              responseClass:[ZNGService class]
                    success:success
                    failure:failure];
}

#pragma mark - POST methods

+ (void)saveService:(ZNGService*)service
            success:(void (^)(ZNGService* service))success
            failure:(void (^)(ZNGError* error))failure {
  if (service.account == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: service.account"];
  }
  
  if (service.displayName == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: service.displayName"];
  }
  
  if (service.timeZone == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: service.timeZone"];
  }
  
  if (service.plan == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: service.plan"];
  }
  
  if (service.serviceAddress == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: service.serviceAddress"];
  }
  
  ZNGNewService* newService = [[ZNGNewService alloc] initWithService:service];
  
  [self postWithModel:newService
                 path:@"services"
        responseClass:[ZNGService class]
              success:success
              failure:failure];
}

#pragma mark - PUT methods

+ (void)updateServiceWithId:(NSString*)serviceId
             withParameters:(NSDictionary*)parameters
                    success:(void (^)(ZNGService* service))success
                    failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString stringWithFormat:@"services/%@", serviceId];
  
  [self putWithPath:path
         parameters:parameters
      responseClass:[ZNGService class]
            success:success
            failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteServiceWithId:(NSString*)serviceId
                    success:(void (^)())success
                    failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString stringWithFormat:@"services/%@", serviceId];
  
  [self deleteWithPath:path success:success failure:failure];
}

@end
