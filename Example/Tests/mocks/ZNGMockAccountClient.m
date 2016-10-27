//
//  ZNGMockAccountClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZNGMockAccountClient.h"

@implementation ZNGMockAccountClient

- (ZNGStatus *)status
{
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    status.totalPages = 1;
    status.totalRecords = [self.accounts count];
    return status;
}

- (void) getAccountListWithSuccess:(void (^)(NSArray* accounts, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    if (success == nil) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        success(self.accounts, [self status]);
    });
}

@end
