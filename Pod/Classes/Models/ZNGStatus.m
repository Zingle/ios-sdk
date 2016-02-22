//
//  ZNGStatus.m
//  Pods
//
//  Created by Ryan Farley on 2/19/16.
//
//

#import "ZNGStatus.h"

@implementation ZNGStatus

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"text" : @"text",
             @"statusCode" : @"status_code",
             @"statusDescription" : @"description",
             @"sortField" : @"sort_field",
             @"sortDirection" : @"sort_direction",
             @"page" : @"page",
             @"pageSize" : @"page_size",
             @"totalPages" : @"total_pages",
             @"totalRecords" : @"total_records"
             };
}

@end
