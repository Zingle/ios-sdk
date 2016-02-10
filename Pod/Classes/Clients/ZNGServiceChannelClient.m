//
//  ZNGServiceChannelClient.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGServiceChannelClient.h"
#import "ZNGConstants.h"
#import "ZNGNewServiceChannel.h"

@implementation ZNGServiceChannelClient

+ (Class)responseObject
{
    return [ZNGServiceChannel class];
}

+ (NSString *)resourcePathWithServiceId:(NSString *)serviceId
{
    if (serviceId == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceId"];
    return [NSString stringWithFormat:kServiceChannelsResourcePath, serviceId];
}

#pragma mark - GET methods

+ (void)serviceChannelWithId:(NSString *)serviceChannelId
               withServiceId:(NSString *)serviceId
                     success:(void (^)(ZNGServiceChannel *serviceChannel))success
                     failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = serviceChannelId ? [NSString stringWithFormat:@"/%@", serviceChannelId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithServiceId:serviceId], idPath];
    
    [self getWithResourcePath:path
               responseClass:[self responseObject]
                      success:success
                      failure:failure];
}

#pragma mark - POST methods

+ (void)saveServiceChannel:(ZNGServiceChannel *)serviceChannel
             withServiceId:(NSString *)serviceId
                   success:(void (^)(ZNGServiceChannel *serviceChannel))success
                   failure:(void (^)(ZNGError *error))failure
{
    if (serviceChannel.channelType.channelTypeId == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceChannel.channelType.channelTypeId"];
    if (serviceChannel.value == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceChannel.value"];
    if (serviceChannel.country == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: serviceChannel.country"];
    
    ZNGNewServiceChannel *newServiceChannel = [[ZNGNewServiceChannel alloc] initWithServiceChannel:serviceChannel];
    [self postWithModel:newServiceChannel
                    path:[self resourcePathWithServiceId:serviceId]
          responseClass:[self responseObject]
                 success:success
                 failure:failure];
}

#pragma mark - PUT methods

+ (void)updateServiceChannelWithId:(NSString *)serviceChannelId
                    withParameters:(NSDictionary *)parameters
                     withServiceId:(NSString *)serviceId
                           success:(void (^)(ZNGServiceChannel *serviceChannel))success
                           failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = serviceChannelId ? [NSString stringWithFormat:@"/%@", serviceChannelId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithServiceId:serviceId], idPath];
    
    [self putWithPath:path
           parameters:parameters
       responseClass:[self responseObject]
              success:success
              failure:failure];
}

#pragma mark - DELETE methods

+ (void)deleteServiceChannelWithId:(NSString *)serviceChannelId
                     withServiceId:(NSString *)serviceId
                           success:(void (^)())success
                           failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = serviceChannelId ? [NSString stringWithFormat:@"/%@", serviceChannelId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithServiceId:serviceId], idPath];
    
    [self deleteWithPath:path
                 success:success
                 failure:failure];
}

@end
