//
//  ZNGUserClient.m
//  Pods
//
//  Created by Jason Neel on 4/5/17.
//
//

#import "ZNGUserClient.h"

@implementation ZNGUserClient

- (void) userWithId:(NSString *)userId
            success:(void (^)(ZNGUser* user, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"services/%@/users/%@", self.accountId, userId];

    [self getWithResourcePath:path
                responseClass:[ZNGUser class]
                      success:success
                      failure:failure];
}

@end
