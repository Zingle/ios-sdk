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

NS_ASSUME_NONNULL_END

@end
