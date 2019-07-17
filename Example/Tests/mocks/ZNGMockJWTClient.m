//
//  ZNGMockJWTClient.m
//  Tests
//
//  Created by Jason Neel on 7/17/19.
//  Copyright © 2019 Zingle. All rights reserved.
//

#import "ZNGMockJWTClient.h"

@implementation ZNGMockJWTClient

- (id) init
{
    return [super initWithZingleURL:[NSURL URLWithString:@"https://api.zingle.me/v1"]];
}

- (void) acquireZingleJwtForUser:(NSString *)user
                        password:(NSString *)password
                         success:(void (^_Nullable)(NSString * jwt))success
                         failure:(void (^_Nullable)(NSError * error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        success(@"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c");
    });
}

- (void) refreshJwt:(NSString *)jwt
            success:(void (^_Nullable)(NSString * jwt))success
            failure:(void (^_Nullable)(NSError * error))failure
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        success(@"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c");
    });
}

@end
