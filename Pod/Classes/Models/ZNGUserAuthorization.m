//
//  ZNGUserAuthorization.m
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import "ZNGUserAuthorization.h"

@implementation ZNGUserAuthorization

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"authorizationClass" : @"authorization_class",
             @"userId" : @"id",
             @"email" : @"email",
             @"firstName" : @"first_name",
             @"lastName" : @"last_name",
             @"title" : @"title"
             };
}

@end
