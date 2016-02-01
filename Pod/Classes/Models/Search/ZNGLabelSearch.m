//
//  ZNGLabelSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGLabelSearch.h"
#import "ZingleModelSearch.h"
#import "ZingleDAO.h"
#import "ZNGService.h"
#import "ZNGLabel.h"

@implementation ZNGLabelSearch

- (void)validate
{
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"Service settings require a Service"];
    }
}

- (NSString *)requestURI
{
    return [NSString stringWithFormat:@"services/%@/contact-labels", self.service.ID];
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id labelData in unpreparedResults )
    {
        ZNGLabel *label  = [[ZNGLabel alloc] initWithService:self.service];
        [label hydrate:labelData];
        [results addObject:label];
    }
    
    return results;
}

@end
