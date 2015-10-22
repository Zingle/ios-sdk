//
//  ZNGContactSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGContactSearch.h"
#import "ZingleDAO.h"
#import "ZNGService.h"
#import "ZNGContact.h"


@implementation ZNGContactSearch

- (void)validate
{
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"Service settings require a Service"];
    }
}

- (NSString *)requestURI
{
    return [NSString stringWithFormat:@"services/%@/contacts", self.service.ID];
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id contactData in unpreparedResults )
    {
        ZNGContact *contact  = [[ZNGContact alloc] initWithService:self.service];
        [contact hydrate:contactData];
        [results addObject:contact];
    }
    
    return results;
}

@end
