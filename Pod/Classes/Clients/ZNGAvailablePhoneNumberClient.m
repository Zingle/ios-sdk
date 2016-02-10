//
//  ZNGAvailablePhoneNumberClient.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGAvailablePhoneNumberClient.h"

@implementation ZNGAvailablePhoneNumberClient

+ (void)availablePhoneNumberListForCountry:(NSString*)country
                                   success:(void (^)(NSArray* availableNumbers))success
                                   failure:(void (^)(ZNGError* error))failure
{
    [self getListWithParameters:@{ @"country" : country }
                           path:@"available-phone-numbers"
                  responseClass:[ZNGAvailablePhoneNumber class]
                        success:success
                        failure:failure];
}

@end
