//
//  ZNGStubbedEventClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import "ZNGStubbedEventClient.h"

@implementation ZNGStubbedEventClient

- (void)eventListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray<ZNGEvent *> * events, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            success(nil, nil);
        }
    });
}

- (void)eventWithId:(NSString*)eventId
            success:(void (^)(ZNGEvent * event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            success(nil, nil);
        }
    });
}

- (void)postInternalNote:(NSString *)note
               toContact:(ZNGContact *)contact
                 success:(void (^)(ZNGEvent * note, ZNGStatus * status))success
                 failure:(void (^)(ZNGError * error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (success) {
            success(nil, nil);
        }
    });
}

@end
