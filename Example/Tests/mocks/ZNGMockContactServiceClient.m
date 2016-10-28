//
//  ZNGMockContactServiceClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/26/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZNGMockContactServiceClient.h"

@implementation ZNGMockContactServiceClient

- (ZNGStatus *)status
{
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    status.totalPages = 1;
    status.totalRecords = [self.contactServices count];
    return status;
}

- (void)contactServiceListWithParameters:(NSDictionary*)parameters
                                 success:(void (^)(NSArray* contactServices, ZNGStatus* status))success
                                 failure:(void (^)(ZNGError* error))failure
{
    if (self.error != nil) {
        if (failure != nil) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                failure(self.error);
            });
        }
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            success(self.contactServices, [self status]);
        });
    }
}

@end
