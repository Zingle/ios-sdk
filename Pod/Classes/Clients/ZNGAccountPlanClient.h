//
//  ZNGAccountPlanClient.h
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGAccountPlan.h"

@interface ZNGAccountPlanClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)accountPlanListWithAccountId:(NSString *)accountId
                      withParameters:(NSDictionary *)parameters
                             success:(void (^)(NSArray *plans))success
                             failure:(void (^)(ZNGError *error))failure;

+ (void)accountPlanWithAccountId:(NSString *)accountId
                      withPlanId:(NSString *)planId
                         success:(void (^)(ZNGAccountPlan *plan))success
                         failure:(void (^)(ZNGError *error))failure;

@end
