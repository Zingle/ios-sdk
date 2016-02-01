//
//  ZNGServiceSettingsSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGServiceSettingsSearch.h"
#import "ZingleModelSearch.h"
#import "ZingleDAO.h"
#import "ZNGService.h"
#import "ZNGCustomField.h"
#import "ZNGCustomFieldValue.h"

@implementation ZNGServiceSettingsSearch

- (void)validate
{
    if( self.service == nil )
    {
        [NSException raise:@"ZINGLE_MISSING_SERVICE" format:@"Service settings require a Service"];
    }
}

- (NSString *)requestURI
{
    return [NSString stringWithFormat:@"services/%@/settings", self.service.ID];
}

- (NSArray *)results
{
    NSArray *unpreparedResults = [self unpreparedResults];
    NSMutableArray *results = [NSMutableArray array];
    
    for( id settingData in unpreparedResults )
    {
        ZNGCustomFieldValue *setting  = [[ZNGCustomFieldValue alloc] initWithService:self.service];
        [setting hydrate:settingData];
        [results addObject:setting];
    }
    
    return results;
}

@end
