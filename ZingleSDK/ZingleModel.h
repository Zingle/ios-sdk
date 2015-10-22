//
//  ZingleModel.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZingleDAO;
@class ZingleSDK;
@class ZingleModelSearch;

@interface ZingleModel : NSObject

@property (nonatomic, retain) ZingleDAO *DAO;
@property (nonatomic, retain) NSString *ID;
@property (nonatomic, retain) NSDate *created, *updated;

- (NSString *)baseURIWithID:(BOOL)withID;
- (NSMutableDictionary *)asDictionary;
- (void)hydrate:(NSMutableDictionary *)data;
- (void)hydrateDates:(NSMutableDictionary *)data;
- (BOOL)isNew;

- (BOOL)refreshWithError:(NSError **)error;
- (void)refreshWithCompletionBlock:(void (^) (void))completionBlock
                       errorBlock:(void (^) (NSError *error))errorBlock;

- (BOOL)saveWithError:(NSError **)error;
- (void)saveWithCompletionBlock:(void (^) (void))completionBlock
                     errorBlock:(void (^) (NSError *error))errorBlock;

- (BOOL)destroyWithError:(NSError **)error;
- (void)destroyWithCompletionBlock:(void (^) (void))completionBlock
                        errorBlock:(void (^) (NSError *error))errorBlock;

- (int)logLevel;
- (void)setLogLevel:(int)logLevel;

@end
