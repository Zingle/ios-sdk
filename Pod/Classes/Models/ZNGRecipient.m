//
//  ZNGRecipient.m
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import "ZNGRecipient.h"

@implementation ZNGRecipient

+(NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"recipientId" : @"id",
             @"channelValue" : @"channel_value"
             };
}

@end
