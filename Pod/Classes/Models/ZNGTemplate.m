//
//  ZNGTemplate.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGTemplate.h"

@implementation ZNGTemplate

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"templateId" : @"id",
             @"displayName" : @"display_name",
             @"subject" : @"subject",
             @"templateTypeCode" : @"templateTypeCode",
             @"body" : @"body",
             @"isGlobal" : @"is_global"
             };
}

@end
