//
//  ZNGNewMessageResponse.m
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import "ZNGNewMessageResponse.h"

@implementation ZNGNewMessageResponse

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"messageIds" : @"message_ids"
             };
}

@end
