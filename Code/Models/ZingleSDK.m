//
//  ZingleSDK.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleSDK.h"
#import "ZingleDAO.h"
#import "ZNGServiceSearch.h"
#import "ZNGTimeZoneSearch.h"
#import "ZNGPlanSearch.h"
#import "ZNGService.h"
#import "ZingleDAOResponse.h"
#import "ZNGAvailablePhoneNumberSearch.h"
#import "ZNGAccountSearch.h"
#import "ZNGAccount.h"
#import "ZNGConversation.h"

NSString * const ZINGLE_API_HOST = @"api.zingle.me";
NSString * const ZINGLE_API_VERSION = @"v1";
NSString * const ZINGLE_ERROR_DOMAIN = @"me.zingle.sdk";

int const ZINGLE_LOG_LEVEL_NONE = 0;
int const ZINGLE_LOG_LEVEL_NOTICE = 1;
int const ZINGLE_LOG_LEVEL_ERROR = 2;
int const ZINGLE_LOG_LEVEL_VERBOSE = 3;

int const ZINGLE_DEFAULT_MAX_ATTACHMENT_SIZE_BYTES = 5120;

// Private
@interface ZingleSDK()

@property (nonatomic, retain) NSString *apiToken, *apiKey;
@property (nonatomic, retain) ZingleDAO *DAO;
@property (nonatomic) int _logLevel;

- (id)initFromSingleton;

@end

// Public
@implementation ZingleSDK

- (id)initFromSingleton
{
    if( self = [super init] )
    {
        self.DAO = [[ZingleDAO alloc] init];
        self.maxAttachmentSizeBytes = ZINGLE_DEFAULT_MAX_ATTACHMENT_SIZE_BYTES;
    }
    return self;
}

+ (ZingleSDK *)sharedSDK
{
    static ZingleSDK *sharedSDK = nil;
    static dispatch_once_t sdkOnceToken;
    
    dispatch_once(&sdkOnceToken, ^{
        sharedSDK = [[ZingleSDK alloc] initFromSingleton];
    });
    
    return sharedSDK;
}

- (void)setToken:(NSString *)token andKey:(NSString *)key
{
    self.apiToken = token;
    self.apiKey = key;
}

- (BOOL)hasCredentials
{
    return (self.apiToken != nil && self.apiKey != nil &&
            [self.apiToken length] > 3 && [self.apiKey length] > 3);
}

- (NSString *)basicAuthString
{
    NSString *credentials = [NSString stringWithFormat:@"%@:%@", self.apiToken, self.apiKey];
    NSData *credentialData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    return [credentialData base64EncodedStringWithOptions:0];
}

- (BOOL)validateCredentialsWithError:(NSError **)error
{
    [self.DAO resetDefaults];
    ZingleDAOResponse *response = [self.DAO sendSynchronousRequestTo:@"" error:error];
    
    return ([response error]) ? NO : YES;
}

- (void)validateCredentialsWithCompletionBlock:( void (^)(void) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    [self.DAO resetDefaults];
    [self.DAO sendAsynchronousRequestTo:@"" completionBlock:^(ZingleDAOResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = [response error];
            if( error ) {
                errorBlock(error);
            } else {
                completionBlock();
            }
        });
    } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)clearCredentials
{
    self.apiToken = nil;
    self.apiKey = nil;
}

- (NSError *)genericError:(NSString *)description code:(int)code
{
    return [NSError errorWithDomain:ZINGLE_ERROR_DOMAIN code:code userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
}

- (ZNGAccount *)findAccountByID:(NSString *)accountID withError:(NSError **)error
{
    ZNGAccount *account = [[ZNGAccount alloc] init];
    account.ID = accountID;
    BOOL found = [account refreshWithError:error];
    return (found) ? account : nil;
}

- (void)findAccountByID:(NSString *)accountID withCompletionBlock:( void (^)(ZNGAccount *account) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGAccount *account = [[ZNGAccount alloc] init];
    account.ID = accountID;
    
    [account refreshWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(account);
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (ZNGService *)findServiceByID:(NSString *)serviceID withError:(NSError **)error
{
    ZNGService *service = [[ZNGService alloc] init];
    service.ID = serviceID;
    BOOL found = [service refreshWithError:error];
    return (found) ? service : nil;
}

- (void)findServiceByID:(NSString *)serviceID withCompletionBlock:( void (^)(ZNGService *service) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGService *service = [[ZNGService alloc] init];
    service.ID = serviceID;
    
    [service refreshWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(service);
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)useServiceWithID:(NSString *)serviceID error:(NSError **)error
{
    self.currentService = [self findServiceByID:serviceID withError:error];
}

- (void)useServiceWithID:(NSString *)serviceID
         completionBlock:( void (^)(void) )completionBlock
              errorBlock:( void (^)(NSError *error) )errorBlock
{
    [self findServiceByID:serviceID withCompletionBlock:^(ZNGService *service) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentService = service;
            completionBlock();
        });
    } errorBlock:^(NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             errorBlock(error);
         });
    }];
}

- (NSArray *)allAccountsWithError:(NSError **)error
{
    ZNGAccountSearch *accountSearch = [[ZNGAccountSearch alloc] init];
    return [accountSearch searchWithError:error];
}

- (void)allAccountsWithCompletionBlock:( void (^)(NSArray *accounts) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGAccountSearch *accountSearch = [[ZNGAccountSearch alloc] init];
    [accountSearch searchWithCompletionBlock:^(NSArray *results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(results);
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (ZNGConversation *)conversationWithService:(ZNGService *)service to:(ZNGMessageCorrespondent *)to usingChannelType:(ZNGChannelType *)channelType
{
    ZNGConversation *conversation = [[ZNGConversation alloc] initWithService:service usingChannelType:channelType];
    [conversation toCorrespondant:to];
    
    return conversation;
}

- (ZNGConversation *)conversationWithService:(ZNGService *)service from:(ZNGMessageCorrespondent *)from usingChannelType:(ZNGChannelType *)channelType
{
    ZNGConversation *conversation = [[ZNGConversation alloc] initWithService:service usingChannelType:channelType];
    [conversation fromCorrespondant:from];
    
    return conversation;
}

- (NSArray *)allTimeZonesWithError:(NSError **)error
{
    ZNGTimeZoneSearch *timeZoneSearch = [[ZNGTimeZoneSearch alloc] init];
    return [timeZoneSearch searchWithError:error];
}

- (void)allTimeZonesWithCompletionBlock:( void (^)(NSArray *timeZones) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGTimeZoneSearch *timeZoneSearch = [[ZNGTimeZoneSearch alloc] init];
    [timeZoneSearch searchWithCompletionBlock:^(NSArray *results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(results);
        });
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

- (void)setGlobalLogLevel:(int)logLevel
{
    self._logLevel = logLevel;
}

- (int)globalLogLevel
{
    return self._logLevel;
}

@end
