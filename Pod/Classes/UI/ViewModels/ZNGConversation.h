//
//  ZNGConversation.h
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGStatus.h"
#import "ZNGMessage.h"
#import "ZNGError.h"
#import "ZNGContact.h"
#import "ZNGService.h"
#import "ZNGMessageClient.h"

@class ZNGContact;
@class ZNGMessage;
@class ZingleSession;
@class ZNGMessageClient;

extern NSString * const ZNGConversationParticipantTypeContact;
extern NSString * const ZNGConversationParticipantTypeService;

@protocol ZNGConversationDelegate <NSObject>

- (void)messagesUpdated:(BOOL)newMessages;
- (void)messagesMarkedAsRead:(BOOL)success;

@end

@interface ZNGConversation : NSObject
{
    NSString * contactId;
}

/**
 *  KVO compliant array of messages.  Observing this with KVO will give array insertion notifications.
 */
@property (nonatomic, strong) NSArray<ZNGMessage *> *messages;

@property (nonatomic,weak) id<ZNGConversationDelegate> delegate;

@property (nonatomic, readonly) ZNGMessageClient * messageClient;

/**
 *  Initializing without a ZNGMessageClient is disallowed
 */
- (id) init NS_UNAVAILABLE;

/**
 *  Initializer.  This is intended to be subclassed and should never be called directly.
 */
- (id) initWithMessageClient:(ZNGMessageClient *)messageClient;

- (void)updateMessages;
- (void)markMessagesAsRead;

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure;

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure;

#pragma mark - Protected methods to be overridden by subclasses
- (ZNGNewMessage *)freshMessage;
- (ZNGParticipant *)sender;
- (ZNGParticipant *)receiver;

// The ID of the local user, either contact ID or service ID
- (NSString *)meId;


@end
