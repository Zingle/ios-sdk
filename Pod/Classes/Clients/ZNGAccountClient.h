//
//  ZNGAccountClient.h
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGAccount.h"

@interface ZNGAccountClient : ZNGBaseClient

#pragma mark - GET methods

- (void) getAccountListWithSuccess:(void (^)(NSArray* accounts, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure;

@end
