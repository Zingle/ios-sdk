//
//  ZingleDAO.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const ZINGLE_REQUEST_METHOD_GET;
extern NSString * const ZINGLE_REQUEST_METHOD_POST;
extern NSString * const ZINGLE_REQUEST_METHOD_PUT;
extern NSString * const ZINGLE_REQUEST_METHOD_DELETE;

@class ZingleSDK;
@class ZingleDAOResponse;

@interface ZingleDAO : NSObject

@property (nonatomic, retain) NSString *requestMethod;
@property (nonatomic, retain) NSMutableDictionary *queryVars, *postVars;

#pragma mark -
#pragma mark Setters

- (void)resetDefaults;
- (void)setQueryVar:(NSString *)value forKey:(NSString *)key;
- (void)deleteQueryVarForKey:(NSString *)key;
- (void)clearQueryVars;
- (void)setPostVar:(id)value forKey:(NSString *)key;
- (void)clearPostVars;

#pragma mark -
#pragma mark Getters

- (NSMutableDictionary *)queryVars;
- (NSMutableDictionary *)postVars;
- (NSString *)requestURLForURI:(NSString *)requestURI;
- (NSString *)queryString;
- (NSString *)jsonPayload;
- (BOOL)isLoading;

# pragma mark -
# pragma mark Commands

- (ZingleDAOResponse *)sendSynchronousRequestTo:(NSString *)requestURI error:(NSError **)zingleError;
- (void)sendAsynchronousRequestTo:(NSString *)requestURI
                  completionBlock:(void (^) (ZingleDAOResponse *response))completionBlock
                       errorBlock:(void (^) (ZingleDAOResponse *response, NSError *error))errorBlock;
- (void)cancel;
- (int)logLevel;
- (void)setLogLevel:(int)logLevel;

@end
