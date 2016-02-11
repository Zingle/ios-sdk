//
//  ZNGMessageRead.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGMessageRead.h"
#import "ZingleValueTransformers.h"

@implementation ZNGMessageRead

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"readAt" : @"read_at"
             };
}

+ (NSValueTransformer*)readAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

@end
