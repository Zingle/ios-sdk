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

- (void) getAccountListWithSuccess:(void (^)(NSArray* accounts, ZNGStatus* status))success
                           failure:(void (^)(ZNGError* error))failure
{
    NSDictionary * parameters = @{ @"page_size" : @(1000) };
    
    [self getListWithParameters:parameters
                           path:@"accounts"
                  responseClass:[ZNGAccount class]
                        success:success
                        failure:failure];
}

@end
