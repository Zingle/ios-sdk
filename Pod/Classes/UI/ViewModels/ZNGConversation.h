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

@interface ZNGConversation : NSObject
{
    NSString * contactId;
}

/**
 *  KVO compliant array of messages.  Observing this with KVO will give array insertion notifications.
 */
@property (nonatomic, strong) NSArray<ZNGMessage *> *messages;

@property (nonatomic, readonly) ZNGMessageClient * messageClient;

/**
 *  The display name for the other end of this conversation.
 *  e.g. if this is a person messaging Hotel Chicago Front Desk, "Hotel Chicago Front Desk"
 */
@property (nonatomic, readonly) NSString * remoteName;

/**
 *  Initializing without a ZNGMessageClient is disallowed
 */
- (id) init NS_UNAVAILABLE;

/**
 *  Initializer.  This is intended to be subclassed and should never be called directly.
 */
- (id) initWithMessageClient:(ZNGMessageClient *)messageClient;

- (void)updateMessages;

/**
 *  Marks the specified messages as read, only if they do not already have read_at dates.
 *  Messages that have already been marked read are ignored.
 */
- (void)markMessagesAsRead:(NSArray<ZNGMessage *> *)messages;

/**
 *  Marks all unread messages as read.
 */
- (void)markAllUnreadMessagesAsRead;

- (void)sendMessageWithBody:(NSString *)body
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure;

- (void)sendMessageWithImage:(UIImage *)image
                     success:(void (^)(ZNGStatus* status))success
                     failure:(void (^) (ZNGError *error))failure;

/**
 *  Returns the last message sent by the same type of person, meaning this will be the prior message sent by the contact
 *   if the supplied message is sent by a contact.  If it is a service, this will likely be the prior message sent by the
 *   same person as a service, but it may also be a different employee.
 */
- (ZNGMessage *) priorMessageWithSameDirection:(ZNGMessage *)message;

#pragma mark - Protected methods to be overridden by subclasses
- (void) addSenderNameToMessages:(NSArray<ZNGMessage *> *)messages;
- (ZNGNewMessage *)freshMessage;
- (ZNGParticipant *)sender;
- (ZNGParticipant *)receiver;

// The ID of the local user, either contact ID or service ID
- (NSString *)meId;


@end
