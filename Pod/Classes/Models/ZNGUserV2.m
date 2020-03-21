//
//  ZNGUserV2.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/20/20.
//

#import "ZNGUserV2.h"

@implementation ZNGUserV2

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"userId" : @"uuid",
             @"username" : @"username",
             @"email" : @"email",
             @"firstName" : @"firstName",
             @"lastName" : @"lastName",
             @"title" : @"title",
             @"avatarUri" : @"avatarUrl",
             };
}

@end
