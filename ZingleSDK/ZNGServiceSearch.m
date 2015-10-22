//
//  ZNGServiceSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGServiceSearch.h"
#import "ZingleModelSearch.h"
#import "ZNGAccount.h"
#import "ZNGService.h"
#import "ZingleDAO.h"

@implementation ZNGServiceSearch

- (NSString *)requestURI
{
    return @"services";
}

- (NSMutableDictionary *)queryVars
{
    NSMutableDictionary *queryVars = [NSMutableDictionary dictionary];
    
    [self ifExistsSetValue:self.phoneNumberPattern forKey:@"phone_number" inDictionary:queryVars];
    [self ifExistsSetValue:self.planId forKey:@"plan_id" inDictionary:queryVars];
    [self ifExistsSetValue:self.serviceDisplayName forKey:@"display_name" inDictionary:queryVars];
    [self ifExistsSetValue:self.serviceAddress forKey:@"address" inDictionary:queryVars];
    [self ifExistsSetValue:self.serviceCity forKey:@"city" inDictionary:queryVars];
    [self ifExistsSetValue:self.serviceState forKey:@"state" inDictionary:queryVars];
    [self ifExistsSetValue:self.servicePostalCode forKey:@"postal_code" inDictionary:queryVars];
    [self ifExistsSetValue:self.serviceCountry forKey:@"country" inDictionary:queryVars];
    
    if( self.account != nil ) {
        [queryVars setValue:self.account.ID forKey:@"account_id"];
    }
    
    return queryVars;
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id serviceData in unpreparedResults )
    {
        ZNGService *service = [[ZNGService alloc] init];
        [service hydrate:serviceData];
        [results addObject:service];
    }
    
    return results;
}

@end
