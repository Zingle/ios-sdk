//
//  ZNGMessageSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGMessageSearch.h"
#import "ZNGService.h"
#import "ZNGMessage.h"

@implementation ZNGMessageSearch

- (void)validate
{
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"Message search requires a Service"];
    }
}

- (NSString *)requestURI
{
    return [NSString stringWithFormat:@"services/%@/messages", self.service.ID];
}

- (NSMutableDictionary *)queryVars
{
    NSMutableDictionary *queryVars = [NSMutableDictionary dictionary];
    
    [self ifExistsSetValue:self.contactId forKey:@"contact_id" inDictionary:queryVars];
    [self ifExistsSetValue:self.contactChannelId forKey:@"contact_channel_id" inDictionary:queryVars];
    [self ifExistsSetValue:self.templateId forKey:@"template_id" inDictionary:queryVars];
    [self ifExistsSetValue:self.communicationDirection forKey:@"communication_direction" inDictionary:queryVars];
    
    NSString *createdAt;
    if( self.createdAfter != nil ) {
        createdAt = [NSString stringWithFormat:@"greater_than(%f)", [self.createdAfter timeIntervalSince1970]];
    } else if( self.createdBefore != nil ) {
        createdAt = [NSString stringWithFormat:@"less_than(%f)", [self.createdBefore timeIntervalSince1970]];
    }
    
    [self ifExistsSetValue:createdAt forKey:@"created_at" inDictionary:queryVars];
    
    return queryVars;
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id messageData in unpreparedResults )
    {
        ZNGMessage *message  = [[ZNGMessage alloc] initWithService:self.service];
        [message hydrate:messageData];
        [results addObject:message];
    }
    
    return results;
}

@end
