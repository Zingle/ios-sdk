//
//  ZingleSDK.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ZINGLE_API_HOST;
extern NSString * const ZINGLE_API_VERSION;
extern NSString * const ZINGLE_ERROR_DOMAIN;

extern int const ZINGLE_LOG_LEVEL_NONE;
extern int const ZINGLE_LOG_LEVEL_NOTICE;
extern int const ZINGLE_LOG_LEVEL_ERROR;
extern int const ZINGLE_LOG_LEVEL_VERBOSE;

extern int const ZINGLE_DEFAULT_MAX_ATTACHMENT_SIZE_BYTES;

@class ZNGServiceSearch;
@class ZNGTimeZoneSearch;
@class ZNGPlanSearch;
@class ZNGService;
@class ZNGAvailablePhoneNumberSearch;
@class ZNGAccountSearch;
@class ZNGAccount;
@class ZNGConversation;
@class ZNGMessageCorrespondent;
@class ZNGChannelType;

@interface ZingleSDK : NSObject

@property (nonatomic) int maxAttachmentSizeBytes;
@property (nonatomic, retain) ZNGService *currentService;

+ (ZingleSDK *)sharedSDK;

- (void)setToken:(NSString *)token andKey:(NSString *)key;
- (BOOL)hasCredentials;
- (void)clearCredentials;
- (NSString *)basicAuthString;

- (BOOL)validateCredentialsWithError:(NSError **)error;
- (void)validateCredentialsWithCompletionBlock:( void (^)(void) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (NSError *)genericError:(NSString *)description code:(int)code;

- (ZNGAccount *)findAccountByID:(NSString *)accountID withError:(NSError **)error;
- (void)findAccountByID:(NSString *)accountID withCompletionBlock:( void (^)(ZNGAccount *account) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (ZNGService *)findServiceByID:(NSString *)serviceID withError:(NSError **)error;
- (void)findServiceByID:(NSString *)serviceID withCompletionBlock:( void (^)(ZNGService *service) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (void)useServiceWithID:(NSString *)serviceID error:(NSError **)error;
- (void)useServiceWithID:(NSString *)serviceID
         completionBlock:( void (^)(void) )completionBlock
              errorBlock:( void (^)(NSError *error) )errorBlock;

- (NSArray *)allAccountsWithError:(NSError **)error;
- (void)allAccountsWithCompletionBlock:( void (^)(NSArray *accounts) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (NSArray *)allTimeZonesWithError:(NSError **)error;
- (void)allTimeZonesWithCompletionBlock:( void (^)(NSArray *timeZones) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (ZNGConversation *)conversationWithService:(ZNGService *)service to:(ZNGMessageCorrespondent *)to usingChannelType:(ZNGChannelType *)channelType;

- (ZNGConversation *)conversationWithService:(ZNGService *)service from:(ZNGMessageCorrespondent *)from usingChannelType:(ZNGChannelType *)channelType;

- (void)setGlobalLogLevel:(int)logLevel;
- (int)globalLogLevel;

@end
