//
//  ZNGTeam.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/4/18.
//

#import "ZNGTeam.h"
#import "ZingleValueTransformers.h"

@implementation ZNGTeam

+ (NSDictionary *) JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(teamId)): @"id",
             NSStringFromSelector(@selector(createdAt)): @"created_at",
             NSStringFromSelector(@selector(userIds)): @"user_ids",
             NSStringFromSelector(@selector(displayName)): @"display_name",
             NSStringFromSelector(@selector(emoji)): @"emoji",
             };
}

+ (NSValueTransformer *) createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

- (NSString * _Nullable) displayNameWithEmoji
{
    if ([self.emoji length] == 0) {
        return self.displayName;
    }
    
    return [NSString stringWithFormat:@"%@ %@", self.emoji, self.displayName];
}

@end
