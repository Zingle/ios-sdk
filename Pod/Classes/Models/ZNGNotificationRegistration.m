//
//  ZNGNotificationRegistration.m
//  Pods
//
//  Created by Ryan Farley on 4/5/16.
//
//

#import "ZNGNotificationRegistration.h"

@implementation ZNGNotificationRegistration

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"deviceIdentifier" : @"device_identifier",
             @"serviceIds" : @"service_ids",
             @"operatingSystem" : @"operating_system",
             NSStringFromSelector(@selector(pushEnvironment)): @"push_environment"
             };
}

@end
