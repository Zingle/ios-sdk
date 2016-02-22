//
//  ZNGAccountClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGAccountClient.h"

@implementation ZNGAccountClient

#pragma mark - GET methods

+ (void)accountListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* accounts, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure
{
    [self getListWithParameters:parameters
                           path:@"accounts"
                  responseClass:[ZNGAccount class]
                        success:success
                        failure:failure];
}

+ (void)accountWithId:(NSString*)accountId
              success:(void (^)(ZNGAccount* account, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    NSString* path = [NSString stringWithFormat:@"accounts/%@", accountId];
    
    [self getWithResourcePath:path
                responseClass:[ZNGAccount class]
                      success:success
                      failure:failure];
}

@end
