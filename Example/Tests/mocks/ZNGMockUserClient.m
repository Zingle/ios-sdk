//
//  ZNGMockUserClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 4/10/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import "ZNGMockUserClient.h"

@implementation ZNGMockUserClient

- (void) userWithId:(NSString *)userId success:(void (^)(ZNGUser *, ZNGStatus *))success failure:(void (^)(ZNGError *))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ZNGStatus * status = [[ZNGStatus alloc] init];
        status.pageSize = 50;
        status.page = 1;
        status.totalPages = (self.user != nil) ? 1 : 0;
        status.totalRecords = status.totalPages;
        
        if (success != nil) {
            success(self.user, status);
        }
    });
}

@end
