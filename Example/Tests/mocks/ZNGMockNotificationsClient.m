//
//  ZNGMockNotificationsClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/2/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZNGMockNotificationsClient.h"
#import "ZingleSDK/ZNGStatus.h"

@implementation ZNGMockNotificationsClient

- (id) initWithSession:(ZingleSession * _Nonnull __weak)session
{
    self = [super initWithSession:session];
    
    if (self != nil) {
        self.registeredServiceIds = [[NSSet alloc] init];
        self.unsubscribedDeviceIds = [[NSSet alloc] init];
    }
    
    return self;
}

- (void) registerForNotificationsWithDeviceId:(NSString *)deviceId withServiceIds:(NSArray *)serviceIds success:(void (^)(ZNGStatus *))success failure:(void (^)(ZNGError *))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableSet<NSString *> * mutableIDs = [self mutableSetValueForKey:NSStringFromSelector(@selector(registeredServiceIds))];
        NSMutableSet<NSString *> * mutableDeviceIds = [self mutableSetValueForKey:NSStringFromSelector(@selector(unsubscribedDeviceIds))];
        [mutableIDs addObjectsFromArray:serviceIds];
        
        if ([serviceIds count] == 0) {
            [mutableDeviceIds addObject:deviceId];
        } else {
            [mutableDeviceIds removeObject:deviceId];
        }
        
        ZNGStatus * status = [[ZNGStatus alloc] init];
        status.statusCode = 200;
        
        if (success != nil) {
            success(status);
        }
    });
}

- (void) unregisterForNotificationsWithDeviceId:(NSString *)deviceId success:(void (^)(ZNGStatus *))success failure:(void (^)(ZNGError *))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableSet<NSString *> * mutableIDs = [self mutableSetValueForKey:NSStringFromSelector(@selector(registeredServiceIds))];
        NSMutableSet<NSString *> * mutableDeviceIds = [self mutableSetValueForKey:NSStringFromSelector(@selector(unsubscribedDeviceIds))];
        [mutableIDs removeAllObjects];
        [mutableDeviceIds addObject:deviceId];
        
        ZNGStatus * status = [[ZNGStatus alloc] init];
        status.statusCode = 200;
        
        if (success != nil) {
            success(status);
        }
    });
}

@end
