//
//  ZingleSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;
@class ZNGAccountClient;
@class ZNGContactClient;
@class ZNGContactServiceClient;
@class ZNGMessageClient;
@class ZNGNotificationsClient;
@class ZNGServiceClient;
@class ZNGUserAuthorizationClient;


/**
 *  This abstract class represents the current session with the Zingle API.  This must be initialized with a set of API credentials.
 *
 *  @see ZingleAccountSession
 *  @see ZingleContactSession
 */
@interface ZingleSession : NSObject

/**
 *  The token identifying the API user.  Immutable after initialization.
 */
@property (nonatomic, readonly, nonnull) NSString * token;

/**
 *  The security key/password of the current API user.  Immutable after initialization.
 */
@property (nonatomic, readonly, nonnull) NSString * key;

/**
 *  The base URL.  Can be overridden only in debug builds.  Immutable after initialization.
 */
@property (nonatomic, readonly, nullable) NSString * baseUrl;

@property (nonatomic, strong, nullable) NSString * pushNotificationDeviceToken;

#pragma mark - Clients
@property (nonatomic, strong, nullable) ZNGAccountClient * accountClient;
@property (nonatomic, strong, nullable) ZNGContactClient * contactClient;
@property (nonatomic, strong, nullable) ZNGContactServiceClient * contactServiceClient;
@property (nonatomic, strong, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, strong, nullable) ZNGNotificationsClient * notificationsClient;
@property (nonatomic, strong, nullable) ZNGServiceClient * serviceClient;
@property (nonatomic, strong, nullable) ZNGUserAuthorizationClient * userAuthorizationClient;

#pragma mark - Properties used by client objects
@property (nonatomic, readonly, nonnull) AFHTTPSessionManager * sessionManager;
@property (nonatomic, readonly, nonnull) dispatch_queue_t jsonProcessingQueue;

/**
 *  Initializer for a Zingle session object.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 */
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key;

@end
