//
//  ZNGAvailablePhoneNumber.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGAvailablePhoneNumber.h"

@implementation ZNGAvailablePhoneNumber

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
  return @{
    @"phoneNumber" : @"phone_number",
    @"formattedPhoneNumber" : @"formatted_phone_number",
    @"country" : @"country"
  };
}

@end
