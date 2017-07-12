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
@class ZNGEventViewModel;
@class ZingleSession;
@class ZNGEventClient;
@class ZNGSocketClient;

extern NSString * _Nonnull const ZNGConversationParticipantTypeContact;
extern NSString * _Nonnull const ZNGConversationParticipantTypeService;
extern NSString * _Nonnull const ZNGConversationParticipantTypeLabel;
extern NSString * _Nonnull const ZNGConversationParticipantTypeGroup;

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
@property (nonatomic, strong, nullable) NSArray<ZNGEvent *> * events;

/**
 *  KVO compliant array of events, expressed as ZNGEventViewModel objects.
 *  Each ZNGEvent in the events array will have at least one ZNGEventViewModel in this array.
 *  In the case of a message event with at least one image attachment, two or more ZNGEventViewModels will exist.
 */
@property (nonatomic, strong, nullable) NSArray<ZNGEventViewModel *> * eventViewModels;

@property (nonatomic) NSInteger totalEventCount;

/**
 *  Flag that is set whenever there is a pending network request
 */
@property (nonatomic) BOOL loading;

/**
 *  Flag that is set to YES once some data has been received from the server.
 *  This can be used to determine whether to display a skeleton view or other initial loading display.
 */
@property (nonatomic, assign) BOOL loadedInitialData;

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

@property (nonatomic, readonly, nullable) ZNGMessageClient * messageClient;
@property (nonatomic, readonly, nullable) ZNGEventClient * eventClient;
@property (nonatomic, strong, nullable) ZNGSocketClient * socketClient;

/**
 *  The display name for the other end of this conversation.
 *  e.g. if this is a person messaging Hotel Chicago Front Desk, "Hotel Chicago Front Desk"
 */
@property (nonatomic, readonly, nullable) NSString * remoteName;

/**
 *  If this conversation is locked by someone else's input or by an automation, a description of the cause will be in this string.
 *  This is usually nil, indicating an unlocked conversation.
 */
@property (nonatomic, strong, nullable) NSString * lockedDescription;

/**
 *  Initializing without a ZNGMessageClient is disallowed
 */
- (nonnull id) init NS_UNAVAILABLE;

/**
 *  Initializer.  This is intended to be subclassed and should never be called directly.
 */
- (nonnull id) initWithMessageClient:(nonnull ZNGMessageClient *)messageClient eventClient:(nonnull ZNGEventClient *)eventClient;

/**
 *  Initializer to copy details from an existing conversation.  This is used for convenience to switch to and from detailed event conversations.
 */
- (nonnull id) initWithConversation:(nonnull ZNGConversation *)conversation;

/**
 *  Populates the events array with the most recent data.
 *
 *  Has no effect if the loading flag is already set.
 */
- (void)loadRecentEventsErasingOlderData:(BOOL)replace;

/**
 *  Fetches one more page of older data if available.
 *
 *  Has no effect if the loading flag is already set.
 */
- (void)loadOlderData;

/**
 *  Marks the specified messages as read, only if they do not already have read_at dates.
 *  Messages that have already been marked read are ignored.
 */
- (void)markMessagesAsRead:(nullable NSArray<ZNGMessage *> *)messages;

/**
 *  Marks all unread messages as read.
 */
- (void)markAllUnreadMessagesAsRead;

- (void)sendMessageWithBody:(nonnull NSString *)body
                    success:(void (^_Nullable)(ZNGStatus* _Nullable status))success
                    failure:(void (^_Nullable) (ZNGError * _Nullable error))failure;

- (void) sendMessageWithBody:(nonnull NSString *)body
                   imageData:(nullable NSArray<NSData *> *)imageData
                        uuid:(nullable NSString *)uuid
                     success:(void (^_Nullable)(ZNGStatus* _Nullable status))success
                     failure:(void (^_Nullable) (ZNGError * _Nullable error))failure;

- (nullable ZNGEvent *) priorEvent:(nonnull ZNGEvent *)event;

/**
 *  Returns the last message sent by the same type of person, meaning this will be the prior message sent by the contact
 *   if the supplied message is sent by a contact.  If it is a service, this will likely be the prior message sent by the
 *   same person as a service, but it may also be a different employee.
 */
- (nullable ZNGMessage *) priorMessageWithSameDirection:(nonnull ZNGMessage *)message;

/**
 *  @returns The most recent message sent from the contact to a service
 */
- (nullable ZNGMessage *) mostRecentInboundMessage;

/**
 *  @returns The most recent message in either direction
 */
- (nullable ZNGMessage *) mostRecentMessage;

#pragma mark - Protected methods that can be called by subclasses
- (void) appendEvents:(nonnull NSArray<ZNGEvent *> *)events;

/**
 *  Removes any events with sending flags
 */
- (void) removeSendingEvents;

#pragma mark - Protected methods to be overridden by subclasses

/**
 *  Array of event types as strings.  (e.g. "message")
 *  Returning nil will result in all events being fetched.
 *
 *  Default implementation returns @[@"message"]
 */
- (nullable NSArray<NSString *> *)eventTypes;

/**
 *  Used to generate an event with a 'sending' flag.  This can be overridden to add user meta data such as avatars.
 */
- (nonnull ZNGEvent *)pendingMessageEventForOutgoingMessage:(nonnull ZNGNewMessage *)newMessage;

- (BOOL) pushNotificationRelevantToThisConversation:(nonnull NSNotification *)notification;

- (void) addSenderNameToEvents:(nullable NSArray<ZNGEvent *> *)events;
- (nonnull ZNGNewMessage *)freshMessage;
- (nonnull ZNGParticipant *)sender;
- (nonnull ZNGParticipant *)receiver;

// The ID of the local user, either contact ID or service ID
- (nonnull NSString *)meId;


@end
