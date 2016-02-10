//
//  ZNGLabel.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGLabel.h"

@implementation ZNGLabel

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"labelId" : @"id",
             @"displayName" : @"display_name",
             @"backgroundColor" : @"background_color",
             @"textColor" : @"text_color",
             @"isGlobal" : @"is_global"
             };
}

@end
