//
//  ZNGEvent.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGUser.h"
#import "ZNGAutomation.h"
#import "ZNGMessage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ZNGEventTypeMessage;
extern NSString * const ZNGEventTypeNote;
extern NSString * const ZNGEventTypeMarkConfirmed;
extern NSString * const ZNGEventTypeMarkUnconfirmed;
extern NSString * const ZNGEventTypeContactCreated;
extern NSString * const ZNGEventTypeWorkflowStarted;
extern NSString * const ZNGEventTypeWorkflowEnded;
extern NSString * const ZNGEventTypeFeedReopened;
extern NSString * const ZNGEventTypeFeedClosed;
extern NSString * const ZNGEventTypeMessageForwarded;
extern NSString * const ZNGEventTypeHotsosIssueCreated;
extern NSString * const ZNGEventTypeAssignmentChange;

@class ZNGContact;
@class ZNGEventViewModel;

@interface ZNGEvent : MTLModel<MTLJSONSerializing, JSQMessageData>

@property (nonatomic, strong) NSString* eventId;
@property (nonatomic, strong, nullable) NSString* contactId;
@property (nonatomic, strong) NSString* eventType;
@property (nonatomic, strong, nullable) NSString* body;
@property (nonatomic, strong) NSDate* createdAt;
@property (nonatomic, strong, nullable) ZNGUser* triggeredByUser;
@property (nonatomic, strong, nullable) ZNGAutomation* automation;
@property (nonatomic, strong, nullable) ZNGMessage* message;

/**
 *  The time this event actually came into existence.  For delayed messages, this will be null until the message is sent.
 *  For most other event types, this is createdAt.
 */
@property (nonatomic, readonly, nullable) NSDate * displayTime;

/**
 *  Local flag indicating that the event is outbound but has not yet been seen in remote data.
 *  e.g. The user hit send on a message, but the server has not yet acknowledged it.
 */
@property (nonatomic, assign) BOOL sending;

/**
 *  An array of one ZNGEventViewModel in the case of an event with no attachments, up to at most one per attachment plus one text for a non-nil body.
 */
@property (nonatomic, readonly) NSArray<ZNGEventViewModel *> * viewModels;

// Added after parsing:
@property (nonatomic, copy) NSString * senderDisplayName;

+ (instancetype) eventForNewMessage:(ZNGMessage *)message;
+ (instancetype) eventForNewNote:(NSString *)note toContact:(ZNGContact *)contact;

+ (NSArray<NSString *> *) recognizedEventTypes;

/**
 *  Should only be explicitly called while creating outbound messages.
 */
- (void) createViewModels;

- (BOOL) isMessage;
- (BOOL) isNote;
- (BOOL) isInboundMessage;

/**
 *  Returns YES if this event type is deletable/mutable.  The only event type where this is true at the moment is delayed message.
 */
- (BOOL) isMutable;

/**
 *  Returns YES if the event has changed since the provided copy.  Always returns NO if isMutable is NO.
 */
- (BOOL) hasChangedSince:(ZNGEvent *)oldEvent;

@end

NS_ASSUME_NONNULL_END
