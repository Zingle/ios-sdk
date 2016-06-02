//
//  ZNGUserAuthorizationClient.h
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGUserAuthorization.h"

@interface ZNGUserAuthorizationClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)userAuthorizationWithSuccess:(void (^)(ZNGUserAuthorization* userAuthorization, ZNGStatus* status))success
                             failure:(void (^)(ZNGError* error))failure;

@end
