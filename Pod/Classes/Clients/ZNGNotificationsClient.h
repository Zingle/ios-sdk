//
//  ZNGNotificationsClient.h
//  Pods
//
//  Created by Ryan Farley on 4/5/16.
//
//

#import "ZNGBaseClient.h"

@interface ZNGNotificationsClient : ZNGBaseClient

#pragma mark - POST methods

+ (void)registerForNotificationsWithDeviceId:(NSString *)deviceId
                              withServiceIds:(NSArray *)serviceIds
                                     success:(void (^)(ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure;

#pragma mark - DELETE methods

+ (void)unregisterForNotificationsWithDeviceId:(NSString *)deviceId
                                       success:(void (^)(ZNGStatus *status))success
                                       failure:(void (^)(ZNGError* error))failure;

@end
