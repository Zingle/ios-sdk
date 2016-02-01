//
//  ZNGCustomFieldSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGContactCustomFieldSearch.h"
#import "ZingleModelSearch.h"
#import "ZingleDAO.h"
#import "ZNGService.h"
#import "ZNGCustomField.h"

@implementation ZNGContactCustomFieldSearch

- (void)validate
{
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"Service settings require a Service"];
    }
}

- (NSString *)requestURI
{
    return [NSString stringWithFormat:@"services/%@/contact-custom-fields", self.service.ID];
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id customFieldData in unpreparedResults )
    {
        ZNGCustomField *customField  = [[ZNGCustomField alloc] init];
        [customField hydrate:customFieldData];
        [results addObject:customField];
    }
    
    return results;
}

@end
