//
//  ZNGEventMetadataEntry.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/2/20.
//

#import "ZNGEventMetadataEntry.h"

NSString * const ZNGEventMetadataEntryMentionTypeUser = @"userMention";
NSString * const ZNGEventMetadataEntryMentionTypeTeam = @"teamMention";

@implementation ZNGEventMetadataEntry

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        NSStringFromSelector(@selector(type)): @"type",
        NSStringFromSelector(@selector(uuid)): @"uuid",
        NSStringFromSelector(@selector(start)): @"start",
        NSStringFromSelector(@selector(end)): @"end",
    };
}

@end
