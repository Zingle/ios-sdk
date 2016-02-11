//
//  ZNGAutomation.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGAutomation.h"

@implementation ZNGAutomation

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return    @{
                @"automationId" : @"id",
                @"displayName" : @"display_name",
                @"type" : @"type",
                @"status" : @"status",
                @"isGlobal" : @"is_global"
                };
}

@end
