//
//  ZingleModelSearch.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZingleSDK;
@class ZingleDAO;
@class ZingleDAOResponse;
@class ZNGService;
@class ZNGAccount;

extern NSString * const ZINGLE_SORT_DIRECTION_ASC;
extern NSString * const ZINGLE_SORT_DIRECTION_DESC;

@interface ZingleModelSearch : NSObject

@property (nonatomic, retain) ZNGAccount *account;
@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) ZingleDAO *DAO;
@property (nonatomic, retain) ZingleDAOResponse *lastResponse;

- (id)initWithAccount:(ZNGAccount *)account;
- (id)initWithService:(ZNGService *)service;

- (void)ifExistsSetValue:(NSString *)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dictionary;
- (BOOL)searching;
- (BOOL)hasResults;
- (NSArray *)unpreparedResults;
- (NSArray *)results;

- (int)page;
- (int)pageSize;
- (void)setPageSize:(int)pageSize;
- (int)totalPages;
- (int)totalRecords;
- (BOOL)hasMore;
- (NSString *)sortField;
- (void)setSortField:(NSString *)sortField;
- (NSString *)sortDirection;
- (void)setSortDirection:(NSString *)sortDirection;

- (NSArray *)searchWithError:(NSError **)error;
- (void)searchWithCompletionBlock:(void (^) (NSArray *results))completionBlock
                       errorBlock:(void (^) (NSError *error))errorBlock;

- (void)cancel;
- (int)logLevel;
- (void)setLogLevel:(int)logLevel;

@end
