//
//  ZNGParticipant.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGParticipant.h"

@implementation ZNGParticipant

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{ @"participantId" : @"id", @"channelValue" : @"channel_value" };
}

@end
