//
//  ZNGAccountSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGAccountSearch.h"
#import "ZingleDAO.h"
#import "ZNGAccount.h"

@implementation ZNGAccountSearch

- (NSString *)requestURI
{
    return @"accounts";
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id accountData in unpreparedResults )
    {
        ZNGAccount *account = [[ZNGAccount alloc] init];
        [account hydrate:accountData];
        [results addObject:account];
    }
    
    return results;
}


@end
