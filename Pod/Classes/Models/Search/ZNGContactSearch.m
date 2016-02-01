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
#import "ZNGContactChannel.h"
#import "ZNGChannelType.h"


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


- (NSMutableDictionary *)queryVars
{
    NSMutableDictionary *queryVars = [NSMutableDictionary dictionary];
    
    [self ifExistsSetValue:self.channelValue forKey:@"channel_value" inDictionary:queryVars];
    [self ifExistsSetValue:self.labelID forKey:@"label_id" inDictionary:queryVars];
    
    return queryVars;
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
