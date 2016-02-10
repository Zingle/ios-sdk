//
//  ZNGAccountPlanClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGAccountPlanClient.h"

@implementation ZNGAccountPlanClient

#pragma mark - GET methods

+ (void)accountPlanListWithAccountId:(NSString*)accountId
                      withParameters:(NSDictionary*)parameters
                             success:(void (^)(NSArray* plans))success
                             failure:(void (^)(ZNGError* error))failure {
  NSString* path = [NSString stringWithFormat:@"accounts/%@/plans", accountId];
  
  [self getListWithParameters:parameters
                         path:path
                responseClass:[ZNGAccountPlan class]
                      success:success
                      failure:failure];
}

+ (void)accountPlanWithAccountId:(NSString*)accountId
                      withPlanId:(NSString*)planId
                         success:(void (^)(ZNGAccountPlan* plan))success
                         failure:(void (^)(ZNGError* error))failure {
  NSString* path =
      [NSString stringWithFormat:@"accounts/%@/plans/%@", accountId, planId];
      
  [self getWithResourcePath:path
              responseClass:[ZNGAccountPlan class]
                    success:success
                    failure:failure];
}

@end
