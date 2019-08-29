//
//  ZNGSocketClient.h
//  Pods
//
//  Created by Jason Neel on 12/15/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZNGConversation;
@class ZingleSession;

@interface ZNGSocketClient : NSObject

- (id) init NS_UNAVAILABLE;

- (id) initWithSession:(ZingleSession *)session;
- (void) connect;
- (void) disconnect;

- (void) userDidType:(nullable NSString *)input;
- (void) userClearedInput;

@property (nonatomic, weak, nullable) ZingleSession * session;

/**
 *  Any conversation set in this property will be subscribed for asynchronous updates.  Updates will be sent to the conversation as they arrive.
 */
@property (nonatomic, weak, nullable) ZNGConversation * activeConversation;

/**
 *  Are we either connected or in the process of connecting?
 */
@property (nonatomic, readonly) BOOL active;

/**
 *  Is our web socket connection initialized and happy?
 */
@property (nonatomic, readonly) BOOL connected;

/**
 *  Should typing indicator messages be ignored if they appear to be from the current user?  Defaults to YES in normal builds and NO in debug builds.
 */
@property (nonatomic, assign) BOOL ignoreCurrentUserTypingIndicator;

/**
 *  If this is non-nil, this user agent string will be sent in headers instead of the normal device user agent.  Defaults to nil, meaning the normal
 *  device user agent will be used, e.g. "Zingle/2 CFNetwork/1098.1 Darwin/18.7.0"
 *  Setting after initial connection has undefined behavior.
 */
@property (nonatomic, copy, nullable) NSString * userAgent;

NS_ASSUME_NONNULL_END

@end
