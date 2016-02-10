//
//  ZNGSender.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGSender.h"

@implementation ZNGSender

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{ @"senderId" : @"id", @"channelValue" : @"channel_value" };
}

@end
