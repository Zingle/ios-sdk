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
@class ZNGMessageClient;
@class ZNGNotificationsClient;
@class ZNGServiceClient;
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
@property (nonatomic, readonly, nonnull) NSString * token;

/**
 *  The security key/password of the current API user.  Immutable after initialization.
 */
@property (nonatomic, readonly, nonnull) NSString * key;

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
 *  The base URL.  Can be overridden only in debug builds.  Immutable after initialization.
 */
@property (nonatomic, readonly, nullable) NSString * baseUrl;

@property (nonatomic, copy, nullable) NSData * pushNotificationDeviceToken;

#pragma mark - Clients
@property (nonatomic, strong, nullable) ZNGAccountClient * accountClient;
@property (nonatomic, strong, nullable) ZNGContactClient * contactClient;
@property (nonatomic, strong, nullable) ZNGContactServiceClient * contactServiceClient;
@property (nonatomic, strong, nullable) ZNGEventClient * eventClient;
@property (nonatomic, strong, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, strong, nullable) ZNGNotificationsClient * notificationsClient;
@property (nonatomic, strong, nullable) ZNGServiceClient * serviceClient;
@property (nonatomic, strong, nullable) ZNGUserAuthorizationClient * userAuthorizationClient;

#pragma mark - Properties used by client objects
@property (nonatomic, readonly, nonnull) AFHTTPSessionManager * sessionManager;
@property (nonatomic, readonly, nonnull) dispatch_queue_t jsonProcessingQueue;

- (nonnull id) init NS_UNAVAILABLE;

/**
 *  Initializer for a Zingle session object.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 */
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key errorHandler:(nullable ZNGErrorHandler)errorHandler NS_DESIGNATED_INITIALIZER;

/**
 *  To be called if the user specifically logs out (vs. just changing account or service.)  This will unregister for push notifications.
 */
- (void) logout NS_REQUIRES_SUPER;

/**
 *  Static setter for the push notification device token.  This allows apps to register this push notification token for later use before a ZingleSession has been initialized.
 */
+ (void) setPushNotificationDeviceToken:(nonnull NSData *)token;

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

@end
