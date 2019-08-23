//
//  ZNGMessage.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGCorrespondent.h"
#import "ZNGUser.h"
#import <JSQMessagesViewController/JSQMessageData.h>

@class ZNGMessageStatus;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGMessage : MTLModel<MTLJSONSerializing, JSQMessageData>

#pragma mark - JSON properties

@property(nonatomic, strong) NSString* messageId;
@property(nonatomic, strong, nullable) NSString* body;
@property(nonatomic, strong, nullable) NSString* displayName;
@property(nonatomic, strong, nullable) NSString* communicationDirection;
@property(nonatomic, strong, nullable) NSString* bodyLanguageCode;
@property(nonatomic, strong, nullable) NSString* translatedBody;
@property(nonatomic, strong, nullable) NSString* translatedBodyLanguageCode;
@property(nonatomic, strong, nullable) ZNGUser* triggeredByUser;
@property(nonatomic, strong, nullable) NSString* templateId;
@property(nonatomic, strong, nullable) NSString* senderType;
@property(nonatomic, strong, nullable) ZNGCorrespondent* sender;
@property(nonatomic, strong, nullable) NSString* recipientType;
@property(nonatomic, strong, nullable) ZNGCorrespondent* recipient;
@property(nonatomic, strong, nullable) NSArray* attachments;
@property(nonatomic, strong, nullable) NSDate* createdAt;
@property(nonatomic, strong, nullable) NSDate* readAt;
@property (nonatomic, copy, nullable) NSString * forwardedByServiceId;
@property(nonatomic, assign) BOOL isDelayed;
@property(nonatomic, strong, nullable) NSDate * executeAt;
@property(nonatomic, strong, nullable) NSDate * executedAt;
@property(nonatomic, strong, nullable) NSArray<ZNGMessageStatus *> * statuses;

/**
 *  If this is an inbound, this is the contact ID.  Outbound, it is the triggered by user ID.
 */
@property (nonatomic, readonly, nullable) NSString * senderPersonId;

#pragma mark - Properties added by containing Conversation
@property (nonatomic, copy, nullable) NSString * senderDisplayName;

/**
 *  Used only for transient outgoing message data objects.  This entire ZNGMessage object will be replaced once the server acknowledges the outbound message.
 */
@property (nonatomic, strong, nullable) NSArray<UIImage *> * outgoingImageAttachments;

/**
 *  If this message was sent from a service and has trigger-er information, that will be returned.  Otherwise, the sender ID will be returned.
 */
- (NSString * _Nullable) triggeredByUserIdOrSenderId;

- (BOOL) isOutbound;

/**
 *  Returns YES if this message has failed to send.  Failure information can be found in the `statuses` array.
 */
- (BOOL) failed;

/**
 *  The sender or receiver, whichever corresponds to a contact.
 */
- (ZNGCorrespondent * _Nullable) contactCorrespondent;

/**
 *  Returns YES if this message has been changed.  Only true when a delayed message is finally sent at the moment.
 */
- (BOOL) hasChangedSince:(ZNGMessage *)oldMessage;

@end

NS_ASSUME_NONNULL_END
