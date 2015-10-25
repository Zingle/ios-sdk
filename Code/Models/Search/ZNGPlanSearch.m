//
//  ZNGPlanSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGPlanSearch.h"
#import "ZingleModelSearch.h"
#import "ZingleDAO.h"
#import "ZNGPlan.h"
#import "ZNGAccount.h"

@implementation ZNGPlanSearch

- (void)validate
{
    if( self.account == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_ACCOUNT" format:@"Must search plans for an Account."];
    }
}

- (NSString *)requestURI
{
    return [NSString stringWithFormat:@"accounts/%@/plans", self.account.ID];
}

- (NSMutableDictionary *)queryVars
{
    NSMutableDictionary *queryVars = [NSMutableDictionary dictionary];
    
    [self ifExistsSetValue:self.code forKey:@"code" inDictionary:queryVars];
    
    return queryVars;
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id planData in unpreparedResults )
    {
        ZNGPlan *plan = [[ZNGPlan alloc] initWithAccount:self.account];
        [plan hydrate:planData];
        [results addObject:plan];
    }
    
    return results;
}

@end
