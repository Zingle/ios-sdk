//
//  ZNGAccountPlanClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGAccountPlanClient.h"
#import "ZNGConstants.h"

@implementation ZNGAccountPlanClient

#pragma mark - ZNGClientProtocol

+ (Class)responseObject
{
    return [ZNGAccountPlan class];
}

+ (NSString *)resourcePathWithAccountId:(NSString *)accountId
{
    if (accountId == nil) [NSException raise:NSInvalidArgumentException format:@"Required argument: accountId"];
    return [NSString stringWithFormat:kAccountPlansResourcePath, accountId];
}

#pragma  mark - GET methods

+ (void)accountPlanListWithAccountId:(NSString *)accountId
                      withParameters:(NSDictionary *)parameters
                             success:(void (^)(NSArray *plans))success
                             failure:(void (^)(ZNGError *error))failure
{
    [self getListWithParameters:parameters
                           path:[self resourcePathWithAccountId:accountId]
                  responseClass:[self responseObject]
                        success:success
                        failure:failure];
}

+ (void)accountPlanWithAccountId:(NSString *)accountId
                      withPlanId:(NSString *)planId
                         success:(void (^)(ZNGAccountPlan *plan))success
                         failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = planId ? [NSString stringWithFormat:@"/%@", planId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePathWithAccountId:accountId], idPath];
    
    [self getWithResourcePath:path
                responseClass:[self responseObject]
                      success:success
                      failure:failure];
}

@end
