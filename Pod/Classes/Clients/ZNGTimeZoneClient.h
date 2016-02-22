//
//  ZNGTimeZoneClient.h
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGBaseClient.h"

@interface ZNGTimeZoneClient : ZNGBaseClient

#pragma mark - GET methods

+ (void)timeZoneListWithSuccess:(void (^)(NSArray* timeZones, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

@end
