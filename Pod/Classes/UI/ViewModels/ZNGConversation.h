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
@class ZNGEvent;
@class ZingleSession;
@class ZNGEventClient;

extern NSString * const ZNGConversationParticipantTypeContact;
extern NSString * const ZNGConversationParticipantTypeService;
extern NSString * const ZNGConversationParticipantTypeLabel;

@interface ZNGConversation : NSObject
{
    NSString * contactId;
}

/**
 *  KVO compliant array of events.  Observing this with KVO will give array insertion notifications.
 *
 *  Depending on the concrete subclass, this array may contain only messages, messages and notes, all events,
 *   or something different depending on the implementation of eventTypes.
 */
@property (nonatomic, strong) NSArray<ZNGEvent *> * events;

@property (nonatomic) NSInteger totalEventCount;

/**
 *  Flag that is set whenever there is a pending network request
 */
@property (nonatomic) BOOL loading;

/**
 *  How many events to load in initial data and in each subsequent call to loadOlderData.  Defaults to 100.
 */
@property (nonatomic) NSUInteger pageSize;

/**
 *  Whether this conversation should make network requests to update its data when a push notification is received.
 *
 *  Defaults to YES.
 */
@property (nonatomic) BOOL automaticallyRefreshesOnPushNotification;

@property (nonatomic, readonly) ZNGMessageClient * messageClient;
@property (nonatomic, readonly) ZNGEventClient * eventClient;

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
- (id) initWithMessageClient:(ZNGMessageClient *)messageClient eventClient:(ZNGEventClient *)eventClient;

/**
 *  Initializer to copy details from an existing conversation.  This is used for convenience to switch to and from detailed event conversations.
 */
- (id) initWithConversation:(ZNGConversation *)conversation;

/**
 *  Populates the events array with the most recent data.
 */
- (void)loadRecentEventsErasingOlderData:(BOOL)replace;

/**
 *  Fetches one more page of older data if available.
 */
- (void)loadOlderData;

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

- (void)sendMessageWithBody:(NSString *)body
                     images:(NSArray<UIImage *> *)images
                    success:(void (^)(ZNGStatus* status))success
                    failure:(void (^) (ZNGError *error))failure;

- (ZNGEvent *) priorEvent:(ZNGEvent *)event;

/**
 *  Returns the last message sent by the same type of person, meaning this will be the prior message sent by the contact
 *   if the supplied message is sent by a contact.  If it is a service, this will likely be the prior message sent by the
 *   same person as a service, but it may also be a different employee.
 */
- (ZNGMessage *) priorMessageWithSameDirection:(ZNGMessage *)message;

/**
 *  @returns The most recent message sent from the contact to a service
 */
- (ZNGMessage *) mostRecentInboundMessage;

/**
 *  @returns The most recent message in either direction
 */
- (ZNGMessage *) mostRecentMessage;

#pragma mark - Protected methods that can be called by subclasses
- (void) appendEvents:(NSArray<ZNGEvent *> *)events;

#pragma mark - Protected methods to be overridden by subclasses

/**
 *  Array of event types as strings.  (e.g. "message")
 *  Returning nil will result in all events being fetched.
 *
 *  Default implementation returns @[@"message"]
 */
- (NSArray<NSString *> *)eventTypes;

- (BOOL) pushNotificationRelevantToThisConversation:(NSNotification *)notification;

- (void) addSenderNameToEvents:(NSArray<ZNGEvent *> *)events;
- (ZNGNewMessage *)freshMessage;
- (ZNGParticipant *)sender;
- (ZNGParticipant *)receiver;

// The ID of the local user, either contact ID or service ID
- (NSString *)meId;


@end
