//
//  ZingleModelSearch.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModelSearch.h"
#import "ZingleSDK.h"
#import "ZingleDAO.h"
#import "ZingleDAOResponse.h"
#import "ZNGService.h"

NSString * const ZINGLE_SORT_DIRECTION_ASC = @"asc";
NSString * const ZINGLE_SORT_DIRECTION_DESC = @"desc";

@interface ZingleModelSearch()

@property (nonatomic) int requestPage, requestPageSize;
@property (nonatomic, retain) NSString *requestSortField, *requestSortDirection;

@end

@implementation ZingleModelSearch

- (id)init
{
    if( self = [super init] ) {
        self.DAO          = [[ZingleDAO alloc] init];
        self.lastResponse = [[ZingleDAOResponse alloc] init];
    }
    
    return self;
}

- (id)initWithAccount:(ZNGAccount *)account
{
    if( self = [super init] )
    {
        self.DAO          = [[ZingleDAO alloc] init];
        self.lastResponse = [[ZingleDAOResponse alloc] init];
        self.account = account;
    }
    return self;
}

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] ) {
        self.DAO          = [[ZingleDAO alloc] init];
        self.lastResponse = [[ZingleDAOResponse alloc] init];
        self.service      = service;
    }
    
    return self;
}

- (void)validate
{
    
}

- (NSString *)requestURI
{
    return @"";
}

- (NSMutableDictionary *)queryVars
{
    return [NSMutableDictionary dictionary];
}

- (void)ifExistsSetValue:(NSString *)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dictionary
{
    if( value != nil && [value length] > 0 ) {
        [dictionary setObject:value forKey:key];
    }
}

- (BOOL)searching
{
    return [self.DAO isLoading];
}

- (BOOL)hasResults
{
    return [self.lastResponse successful];
}

- (NSArray *)unpreparedResults
{
    NSArray *results = [NSArray array];
    
    if( [self hasResults] ) {
        results = [self.lastResponse result];
    }
    
    return results;
}

- (NSArray *)results
{
    return [NSArray array];
}

- (NSArray *)searchWithError:(NSError **)error
{
    self.requestPage = 1;
    [self sendSearchRequestWithError:error];
    if( error == nil ) {
        return [self results];
    }
    return nil;
}

- (void)searchWithCompletionBlock:(void (^) (NSArray *results))completionBlock
                       errorBlock:(void (^) (NSError *error))errorBlock
{
    self.requestPage = 1;
    
    self.lastResponse = [[ZingleDAOResponse alloc] init];
    
    [self sendSearchRequestWithCompletionBlock:^(ZingleDAOResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock( [self results] );
        });
    } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock( error );
        });
    }];
}

- (void)sendSearchRequestWithCompletionBlock:(void (^) (ZingleDAOResponse *response))completionBlock
                                  errorBlock:(void (^) (ZingleDAOResponse *response, NSError *error))errorBlock
{
    self.lastResponse = [[ZingleDAOResponse alloc] init];
    
    [self prepareDAO];
    
    [self.DAO sendAsynchronousRequestTo:[self requestURI]
                        completionBlock:^(ZingleDAOResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastResponse = response;
            completionBlock(response);
        });
    }
                             errorBlock:^(ZingleDAOResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastResponse = response;
            errorBlock(response, error);
        });
    }];
}

- (void)sendSearchRequestWithError:(NSError **)error
{
    self.lastResponse = [[ZingleDAOResponse alloc] init];
    [self prepareDAO];
    self.lastResponse = [self.DAO sendSynchronousRequestTo:[self requestURI] error:error];
}

- (void)prepareDAO
{
    [self validate];
    
    [self.DAO resetDefaults];
    [self.DAO setRequestMethod:ZINGLE_REQUEST_METHOD_GET];
    [self.DAO setQueryVars:[self queryVars]];
    
    if( self.requestPage > 0 ) {
        [self.DAO setQueryVar:[NSString stringWithFormat:@"%i", self.requestPage] forKey:@"page"];
    }
    
    if( self.requestPageSize > 0 && self.requestPageSize < 1000 ) {
        [self.DAO setQueryVar:[NSString stringWithFormat:@"%i", self.requestPageSize] forKey:@"page_size"];
    }
    
    if( self.requestSortField != nil && [self.requestSortField length] > 0 ) {
        [self.DAO setQueryVar:self.requestSortField forKey:@"sort_field"];
        
        if( self.requestSortDirection != nil && [self.requestSortDirection length] > 0 ) {
            [self.DAO setQueryVar:self.requestSortDirection forKey:@"sort_direction"];
        }
    }
}

- (void)cancel
{
    [self.DAO cancel];
}

- (int)page
{
    if( [self hasResults] ) {
        id page = [self.lastResponse statusField:@"page"];
        
        if( page ) {
            return [page intValue];
        }
    }
    
    return 0;
}

- (int)pageSize
{
    if( [self hasResults] ) {
        id pageSize = [self.lastResponse statusField:@"page_size"];
        
        if( pageSize ) {
            return [pageSize intValue];
        }
    }
    
    return self.requestPageSize;
}

- (void)setPageSize:(int)pageSize
{
    if( pageSize >= 1 && pageSize <= 1000 ) {
        self.requestPageSize = pageSize;
    } else {
        [NSException raise:@"ZINGLE_SDK_INVALID_PAGE_SIZE" format:@"Search page size must be between 1 and 1000"];
    }
}

- (int)totalPages
{
    if( [self hasResults] ) {
        id totalPages = [self.lastResponse statusField:@"total_pages"];
        
        if( totalPages ) {
            return [totalPages intValue];
        }
    }
    
    return 0;
}

- (int)totalRecords
{
    if( [self hasResults] ) {
        id totalRecords = [self.lastResponse statusField:@"total_records"];
        
        if( totalRecords ) {
            return [totalRecords intValue];
        }
    }
    
    return 0;
}

- (BOOL)hasMore
{
    if( [self hasResults] ) {
        if( [self page] < [self totalPages] ) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)sortField
{
    if( [self hasResults] ) {
        NSString *sortField = [self.lastResponse statusField:@"sort_field"];
        
        if( sortField ) {
            return sortField;
        }
    }
    
    return self.requestSortField;
}

- (void)setSortField:(NSString *)sortField
{
    self.requestSortField = sortField;
}

- (NSString *)sortDirection
{
    if( [self hasResults] ) {
        NSString *sortDirection = [self.lastResponse statusField:@"sort_direction"];
        
        if( sortDirection ) {
            return sortDirection;
        }
    }
    
    return self.requestSortDirection;
}

- (void)setSortDirection:(NSString *)sortDirection
{
    if( [sortDirection isEqualToString:ZINGLE_SORT_DIRECTION_ASC] ||
        [sortDirection isEqualToString:ZINGLE_SORT_DIRECTION_DESC] ) {
        self.requestSortDirection = sortDirection;
    } else {
        [NSException raise:@"ZINGLE_SDK_INVALID_SORT_DIRECTION" format:@"Invalid sort direction."];
    }
}

- (NSString *)description
{
    return [self.lastResponse description];
}

- (int)logLevel
{
    return [self.DAO logLevel];
}

- (void)setLogLevel:(int)logLevel
{
    [self.DAO setLogLevel:logLevel];
}

@end
