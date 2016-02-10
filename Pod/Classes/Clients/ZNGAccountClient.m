//
//  ZNGAccountClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGAccountClient.h"
#import "ZNGConstants.h"

@implementation ZNGAccountClient

+ (Class)responseObject
{
    return [ZNGAccount class];
}

+ (NSString *)resourcePath
{
    return kAccountsResourcePath;
}

#pragma mark - GET methods

+ (void)accountListWithParameters: (NSDictionary *)parameters
                          success:(void (^)(NSArray *accounts))success
                          failure:(void (^)(ZNGError *error))failure
{
    [self getListWithParameters:parameters
                           path:[self resourcePath]
                  responseClass:[self responseObject]
                        success:success
                        failure:failure];
}

+ (void)accountWithId:(NSString *)accountId
              success:(void (^)(ZNGAccount *account))success
              failure:(void (^)(ZNGError *error))failure
{
    NSString *idPath = accountId ? [NSString stringWithFormat:@"/%@", accountId] : @"";
    NSString *path = [NSString stringWithFormat:@"%@%@",[self resourcePath], idPath];
    
    [self getWithResourcePath:path
                responseClass:[self responseObject]
                      success:success
                      failure:failure];
}

@end
