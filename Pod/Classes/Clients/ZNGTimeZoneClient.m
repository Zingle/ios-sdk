//
//  ZNGTimeZoneClient.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGTimeZoneClient.h"

@implementation ZNGTimeZoneClient

#pragma mark - GET methods

+ (void)timeZoneListWithSuccess:(void (^)(NSArray* timeZones))success
                        failure:(void (^)(ZNGError* error))failure {
  [self getListWithParameters:nil
                         path:@"time-zones"
                responseClass:[NSString class]
                      success:success
                      failure:failure];
}

@end
