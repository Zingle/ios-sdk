//
//  ZNGNotificationsClient.m
//  Pods
//
//  Created by Ryan Farley on 4/5/16.
//
//

#import "ZNGNotificationsClient.h"
#import "ZNGNotificationRegistration.h"

@implementation ZNGNotificationsClient

#pragma mark - POST methods

- (void)registerForNotificationsWithDeviceId:(NSString *)deviceId
                              withServiceIds:(NSArray *)serviceIds
                                     success:(void (^)(ZNGStatus *status))success
                                     failure:(void (^)(ZNGError* error))failure
{
    ZNGNotificationRegistration *registration = [[ZNGNotificationRegistration alloc] init];
    registration.deviceIdentifier = deviceId;
    registration.serviceIds = serviceIds;
    registration.operatingSystem = @"ios";
    
    NSString *path = @"receive-notifications";
    
    [self postWithModel:registration
                   path:path
          responseClass:nil
                success:^(id responseObject, ZNGStatus *status) {
                    if (success != nil) {
                        success(status);
                    }
                }
                failure:failure];
}

#pragma mark - DELETE methods

- (void)unregisterForNotificationsWithDeviceId:(NSString *)deviceId
                                       success:(void (^)(ZNGStatus *status))success
                                       failure:(void (^)(ZNGError* error))failure
{
    ZNGNotificationRegistration *registration = [[ZNGNotificationRegistration alloc] init];
    registration.deviceIdentifier = deviceId;
    registration.serviceIds = @[];
    registration.operatingSystem = @"ios";
    
    NSString *path = @"receive-notifications";
    
    [self postWithModel:registration
                   path:path
          responseClass:nil
                success:^(id responseObject, ZNGStatus *status) {
                    if (success != nil) {
                        success(status);
                    }
                } failure:failure];
}

@end