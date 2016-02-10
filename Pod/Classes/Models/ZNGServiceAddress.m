//
//  ZNGServiceAddress.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZNGServiceAddress.h"

@implementation ZNGServiceAddress

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
  return @{
    @"address" : @"address",
    @"city" : @"city",
    @"state" : @"state",
    @"country" : @"country",
    @"postalCode" : @"postal_code"
  };
}

@end
