//
//  ZNGTimeZoneSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGTimeZoneSearch.h"
#import "ZingleModelSearch.h"
#import "ZingleDAO.h"

@implementation ZNGTimeZoneSearch

- (NSString *)requestURI
{
    return @"time-zones";
}

- (NSArray *)results
{
    return [self unpreparedResults];
}

@end
