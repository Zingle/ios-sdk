//
//  ZNGCorrespondent.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGCorrespondent.h"
#import "ZNGChannel.h"

@implementation ZNGCorrespondent

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"correspondentId" : @"id",
             @"channel" : @"channel"
             };
}

+ (NSValueTransformer*)channelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:ZNGChannel.class];
}

@end
