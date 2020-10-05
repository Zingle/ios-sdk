//
//  ZingleSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import <Foundation/Foundation.h>
#import "ZingleSDK.h"

@class AFHTTPSessionManager;
@class ZNGAccountClient;
@class ZNGContactClient;
@class ZNGContactServiceClient;
@class ZNGEventClient;
@class ZNGJWTClient;
@class ZNGMessageClient;
@class ZNGNotificationsClient;
@class ZNGServiceClient;
@class ZNGSocketClient;
@class ZNGUserAuthorizationClient;
@class ZNGError;

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
@property (nonatomic, readonly, nullable) NSString * token;

/**
 *  The security key/password of the current API user.  Immutable after initialization.
 */
@property (nonatomic, readonly, nullable) NSString * key;

/**
 *  The JWT token of the current user.  This will be refreshed and replaced automatically.
 */
@property (nonatomic, copy, nullable) NSString * jwt;

/**
 *  KVO compliant flag that indicates when the session has been fully initialized and may take requests.
 */
@property (nonatomic, assign) BOOL available;

/**
 *  KVO compliant property holding the most recent error.  This is not cleared except to be replaced.
 */
@property (nonatomic, strong, nullable) ZNGError * mostRecentError;

/**
 *  The block automatically called upon any error.  This block is retained throughout the lifetime of the session
 *   object, so weak references should be used.
 */
@property (nonatomic, copy, nullable) ZNGErrorHandler errorHandler;

/**
 *  The base URL.  Immutable after initialization.
 *
 *  Defaults to "https://api.zingle.me/v1/"
 */
@property (nonatomic, copy, nonnull) NSString * urlString;

#pragma mark - Clients
@property (nonatomic, strong, nullable) ZNGAccountClient * accountClient;
@property (nonatomic, strong, nullable) ZNGContactClient * contactClient;
@property (nonatomic, strong, nullable) ZNGContactServiceClient * contactServiceClient;
@property (nonatomic, strong, nullable) ZNGEventClient * eventClient;
@property (nonatomic, strong, nullable) ZNGJWTClient * jwtClient;
@property (nonatomic, strong, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, strong, nullable) ZNGNotificationsClient * notificationsClient;
@property (nonatomic, strong, nullable) ZNGServiceClient * serviceClient;
@property (nonatomic, strong, nullable) ZNGSocketClient * socketClient;
@property (nonatomic, strong, nullable) ZNGUserAuthorizationClient * userAuthorizationClient;

#pragma mark - Properties used by client objects
@property (nonatomic, strong, nonnull) AFHTTPSessionManager * sessionManager;
@property (nonatomic, strong, nonnull) AFHTTPSessionManager * v2SessionManager; // Session manager for the V2 Zingle API
@property (nonatomic, readonly, nonnull) dispatch_queue_t jsonProcessingQueue;

- (nonnull id) init NS_UNAVAILABLE;

/**
 *  Basic auth initializer for a Zingle session object.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 */
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key NS_DESIGNATED_INITIALIZER;

/**
 *  JWT initializer for a Zingle session object.
 *
 *  @param jwt A valid Zingle JWT
 */
- (nonnull instancetype) initWithJWT:(nonnull NSString *)jwt NS_DESIGNATED_INITIALIZER;

/**
 *  Refreshes an existing JWT if possible.  Fails if the JWT is too old to refresh or no JWT is present.
 *  Calling mutiple times simultaneously may result in a single completion callback.
 */
- (void) refreshJwt:(void (^_Nullable)(BOOL success, NSError * _Nullable error))completion;

/**
 *  To be called if the user specifically logs out (vs. just changing account or service.)  This will unregister for push notifications.
 */
- (void) logout NS_REQUIRES_SUPER;

/**
 *  Ends the current session, optionally keeping push notifications working.
 */
- (void) logoutPreservingPushNotifications:(BOOL)keepPushSubscriptions;

/**
 *  Reset the password associated with the provided email address.
 */
+ (void) resetPasswordForEmail:(nonnull NSString *)email completion:(void (^_Nullable)(BOOL success))completion;

/*
 *  Start the connection by requesting initial data
 */
- (void) connect;

/**
 *  Static setter for the push notification device token.  This allows apps to register this push notification token for later use before a ZingleSession has been initialized.
 */
+ (void) setPushNotificationDeviceToken:(nonnull NSData *)token
    __attribute__((deprecated("Notifications via normal APNS has been deprecated in favor of Firebase.  Use `setFirebaseToken:` instead.")));

/**
 *  Static setter for a Firebase FCM token.  This allows apps to register this push notification token for later use before a ZingleSession has been initialized.
 */
+ (void) setFirebaseToken:(nonnull NSString *)token;

/**
 *  Private method used by subclasses to subscribe for push notifications.
 *  Has no effect if pushNotificationDeviceToken is not set.
 */
- (void) _registerForPushNotificationsForServiceIds:(NSArray<NSString *> * _Nonnull)serviceIds removePreviousSubscriptions:(BOOL)removePrevious;

/**
 *  Private method used when all push notifications registrations should be removed without adding any new ones (such as during a logout)
 *
 *  @note Use _registerForPushNotificationsForServiceIds:removePreviousSubscriptions: instead if new subscriptions should be added simultaneously.
 */
- (void) _unregisterForAllPushNotifications;

+ (nonnull AFHTTPSessionManager *) anonymousSessionManagerWithURL:(nonnull NSURL *)url;

@end
