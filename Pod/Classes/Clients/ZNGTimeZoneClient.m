//
//  ZNGTimeZoneClient.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGTimeZoneClient.h"
#import "ZNGConstants.h"

@implementation ZNGTimeZoneClient

#pragma mark - ZNGClientProtocol

+ (Class)responseObject
{
    return [NSString class];
}

+ (NSString *)resourcePath
{
    return kTimeZoneResourcePath;
}

#pragma mark - GET methods

+ (void)timeZoneListWithSuccess:(void (^)(NSArray *timeZones))success
                        failure:(void (^)(ZNGError *error))failure
{
    [self getListWithParameters:nil
                           path:[self resourcePath]
                 responseClass:[self responseObject]
                        success:success
                        failure:failure];
}

@end
