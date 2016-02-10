//
//  ZNGAvailablePhoneNumberClient.h
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGBaseClient.h"
#import "ZNGAvailablePhoneNumber.h"

@interface ZNGAvailablePhoneNumberClient : ZNGBaseClient

+ (void)availablePhoneNumberListForCountry:(NSString *)country
                                   success:(void (^)(NSArray *availableNumbers))success
                                   failure:(void (^)(ZNGError *error))failure;

@end
