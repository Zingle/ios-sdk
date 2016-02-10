//
//  ZNGAccount.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZNGAccount.h"
#import "ZingleValueTransformers.h"

@implementation ZNGAccount

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"accountId" : @"id",
             @"displayName" : @"display_name",
             @"termMonths" : @"term_months",
             @"currentTermStartDate" : @"current_term_start_date",
             @"currentTermEndDate" : @"current_term_end_date",
             @"createdAt" : @"created_at",
             @"updatedAt" : @"updated_at"
             };
}

+ (NSValueTransformer*)currentTermStartDateJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)currentTermEndDateJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)createdAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

+ (NSValueTransformer*)updatedAtJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

@end
