//
//  ZNGServiceChannelClient.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGServiceChannel.h"

@interface ZNGServiceChannelClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)serviceChannelWithId:(NSString*)serviceChannelId
               withServiceId:(NSString*)serviceId
                     success:(void (^)(ZNGServiceChannel* serviceChannel))success
                     failure:(void (^)(ZNGError* error))failure;

#pragma mark - POST methods

+ (void)saveServiceChannel:(ZNGServiceChannel*)serviceChannel
             withServiceId:(NSString*)serviceId
                   success:(void (^)(ZNGServiceChannel* serviceChannel))success
                   failure:(void (^)(ZNGError* error))failure;

#pragma mark - PUT methods

+ (void)updateServiceChannelWithId:(NSString*)serviceChannelId
                    withParameters:(NSDictionary*)parameters
                     withServiceId:(NSString*)serviceId
                           success:(void (^)(ZNGServiceChannel* serviceChannel))success
                           failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)deleteServiceChannelWithId:(NSString*)serviceChannelId
                     withServiceId:(NSString*)serviceId
                           success:(void (^)())success
                           failure:(void (^)(ZNGError* error))failure;

@end
