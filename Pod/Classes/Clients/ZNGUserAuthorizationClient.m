//
//  ZNGUserAuthorizationClient.m
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import "ZNGUserAuthorizationClient.h"

@implementation ZNGUserAuthorizationClient

#pragma mark - GET methods

+ (void)userAuthorizationWithSuccess:(void (^)(ZNGUserAuthorization* userAuthorization, ZNGStatus* status))success
                             failure:(void (^)(ZNGError* error))failure {
    
    [self getWithResourcePath:@""
                responseClass:[ZNGUserAuthorization class]
                      success:success
                      failure:failure];
}

@end
