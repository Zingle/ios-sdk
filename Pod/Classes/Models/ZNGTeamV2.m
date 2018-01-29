//
//  ZNGTeamV2.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import "ZNGTeamV2.h"

@implementation ZNGTeamV2

+ (NSDictionary *) JSONKeyPathsByPropertyKey
{
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
                        NSStringFromSelector(@selector(teamId)): @"uuid",
                        NSStringFromSelector(@selector(numericId)): @"id",
                        NSStringFromSelector(@selector(emoji)): @"emojiCode",
                        NSStringFromSelector(@selector(displayName)): @"name",
            }];
}

@end
