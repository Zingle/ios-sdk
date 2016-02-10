//
//  ZNGAvailablePhoneNumberClient.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGAvailablePhoneNumberClient.h"
#import "ZNGConstants.h"

@implementation ZNGAvailablePhoneNumberClient

+ (Class)responseObject
{
    return [ZNGAvailablePhoneNumber class];
}

+ (NSString *)resourcePath
{
    return kAvailablePhoneNumbersPath;
}

+ (void)availablePhoneNumberListForCountry:(NSString *)country
                                   success:(void (^)(NSArray *availableNumbers))success
                                   failure:(void (^)(ZNGError *error))failure
{
    [self getListWithParameters:@{@"country" : country}
                           path:[self resourcePath]
                 responseClass:[self responseObject]
                        success:success
                        failure:failure];
}

@end
