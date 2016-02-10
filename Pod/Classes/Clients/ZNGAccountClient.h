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

+ (void)accountListWithParameters: (NSDictionary *)parameters
                          success:(void (^)(NSArray *accounts))success
                          failure:(void (^)(ZNGError *error))failure;

+ (void)accountWithId:(NSString *)accountId
              success:(void (^)(ZNGAccount *account))success
              failure:(void (^)(ZNGError *error))failure;

@end
