//
//  ZNGAvailablePhoneNumberSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGAvailablePhoneNumberSearch.h"
#import "ZingleModelSearch.h"
#import "ZingleDAO.h"
#import "ZNGAvailablePhoneNumber.h"
#import "ZNGService.h"

@implementation ZNGAvailablePhoneNumberSearch

- (void)validate
{
    if( !(self.country != nil && [self.country length] > 0) ) {
        [NSException raise:@"ZINGLE_COUNTRY_REQUIRED" format:@"Country is required to search available phone numbers."];
    }
}

- (NSString *)requestURI
{
    return @"available-phone-numbers";
}

- (NSMutableDictionary *)queryVars
{
    NSMutableDictionary *queryVars = [NSMutableDictionary dictionary];
    
    [queryVars setObject:self.country forKey:@"country"];
    
    if( self.areaCode != nil && [self.areaCode length] > 0 ) {
        [queryVars setObject:[NSString stringWithFormat:@"%@*******", self.areaCode] forKey:@"search"];
    } else {
        [self ifExistsSetValue:self.searchPattern forKey:@"search" inDictionary:queryVars];
    }
    
    return queryVars;
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id availablePhoneNumberData in unpreparedResults ) {
        ZNGAvailablePhoneNumber *phoneNumber = [[ZNGAvailablePhoneNumber alloc] init];
        [phoneNumber hydrate:availablePhoneNumberData];
        phoneNumber.service = self.service;
        [results addObject:phoneNumber];
    }
    
    return results;
}

@end
