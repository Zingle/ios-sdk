//
//  ZNGServiceChannelClient.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewChannel.h"
#import "ZNGServiceChannelClient.h"

@implementation ZNGServiceChannelClient

#pragma mark - GET methods

+ (void)serviceChannelWithId:(NSString*)serviceChannelId
               withServiceId:(NSString*)serviceId
                     success:(void (^)(ZNGChannel* serviceChannel, ZNGStatus* status))success
                     failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/channels/%@", serviceId, serviceChannelId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGChannel class]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveServiceChannel:(ZNGChannel*)serviceChannel
             withServiceId:(NSString*)serviceId
                   success:(void (^)(ZNGChannel* serviceChannel, ZNGStatus* status))success
                   failure:(void (^)(ZNGError* error))failure
{
    if (serviceChannel.channelType.channelTypeId == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceChannel.channelType.channelTypeId"];
    }
    
    if (serviceChannel.value == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceChannel.value"];
    }
    
    if (serviceChannel.country == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceChannel.country"];
    }
    
    ZNGNewChannel* newServiceChannel = [[ZNGNewChannel alloc] initWithChannel:serviceChannel];
    
    NSString* path = [NSString stringWithFormat:@"services/%@/channels", serviceId];
    
    [self postWithModel:newServiceChannel
                   path:path
          responseClass:[ZNGChannel class]
                success:success
                failure:failure];
}

#pragma mark - PUT methods

+ (void)updateServiceChannelWithId:(NSString*)serviceChannelId
                    withParameters:(NSDictionary*)parameters
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGChannel* serviceChannel, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/channels/%@", serviceId, serviceChannelId];
    
    [self putWithPath:path
           parameters:parameters
        responseClass:[ZNGNewChannel class]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteServiceChannelWithId:(NSString*)serviceChannelId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/channels/%@", serviceId, serviceChannelId];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
