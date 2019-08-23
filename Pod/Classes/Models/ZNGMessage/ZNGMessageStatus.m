//
//  ZNGMessageStatus.m
//  ZingleSDK
//
//  Created by Jason Neel on 8/23/19.
//

#import "ZNGMessageStatus.h"
#import "ZingleValueTransformers.h"

NSString * const ZNGMessageStatusTypeFailed = @"failed";

@implementation ZNGMessageStatus

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(type)): @"type",
             NSStringFromSelector(@selector(statusDescription)): @"description",
             NSStringFromSelector(@selector(createdAt)): @"created_at",
             };
}

+ (NSValueTransformer *)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

- (BOOL) isFailure
{
    return [self.type isEqualToString:ZNGMessageStatusTypeFailed];
}

@end

