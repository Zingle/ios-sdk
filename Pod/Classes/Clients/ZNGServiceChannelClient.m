//
//  ZNGServiceChannelClient.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewServiceChannel.h"
#import "ZNGServiceChannelClient.h"

@implementation ZNGServiceChannelClient

#pragma mark - GET methods

+ (void)serviceChannelWithId:(NSString*)serviceChannelId
               withServiceId:(NSString*)serviceId
                     success:
                         (void (^)(ZNGServiceChannel* serviceChannel))success
                     failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/channels/%@", serviceId, serviceChannelId];
      
  [self getWithResourcePath:path
              responseClass:[ZNGServiceChannel class]
                    success:success
                    failure:failure];
}

#pragma mark - POST methods

+ (void)saveServiceChannel:(ZNGServiceChannel*)serviceChannel
             withServiceId:(NSString*)serviceId
                   success:(void (^)(ZNGServiceChannel* serviceChannel))success
                   failure:(void (^)(ZNGError* error))failure {
  if (serviceChannel.channelType.channelTypeId == nil) {
    [NSException
         raise:NSInvalidArgumentException
        format:@"Required argument: serviceChannel.channelType.channelTypeId"];
  }
  
  if (serviceChannel.value == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: serviceChannel.value"];
  }
  
  if (serviceChannel.country == nil) {
    [NSException raise:NSInvalidArgumentException
                format:@"Required argument: serviceChannel.country"];
  }
  
  ZNGNewServiceChannel* newServiceChannel =
      [[ZNGNewServiceChannel alloc] initWithServiceChannel:serviceChannel];
      
  NSString* path =
      [NSString stringWithFormat:@"services/%@/channels", serviceId];
      
  [self postWithModel:newServiceChannel
                 path:path
        responseClass:[ZNGServiceChannel class]
              success:success
              failure:failure];
}

#pragma mark - PUT methods

+ (void)updateServiceChannelWithId:(NSString*)serviceChannelId
                    withParameters:(NSDictionary*)parameters
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGServiceChannel* serviceChannel))
                                       success
                           failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/channels/%@", serviceId, serviceChannelId];
      
  [self putWithPath:path
         parameters:parameters
      responseClass:[ZNGServiceChannel class]
            success:success
            failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteServiceChannelWithId:(NSString*)serviceChannelId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)())success
                           failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString
      stringWithFormat:@"services/%@/channels/%@", serviceId, serviceChannelId];
      
  [self deleteWithPath:path success:success failure:failure];
}

@end
