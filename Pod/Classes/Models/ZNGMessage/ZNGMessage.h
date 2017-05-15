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

// Posted through NSNotificationCenter when media has finished downloading
#define kZNGMessageMediaLoadedNotification  @"kZNGMessageMediaLoadedNotification"

@interface ZNGMessage : MTLModel<MTLJSONSerializing, JSQMessageData>

#pragma mark - JSON properties
@property(nonatomic, strong) NSString* messageId;
@property(nonatomic, strong) NSString* body;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* communicationDirection;
@property(nonatomic, strong) NSString* bodyLanguageCode;
@property(nonatomic, strong) NSString* translatedBody;
@property(nonatomic, strong) NSString* translatedBodyLanguageCode;
@property(nonatomic, strong) ZNGUser* triggeredByUser;
@property(nonatomic, strong) NSString* templateId;
@property(nonatomic, strong) NSString* senderType;
@property(nonatomic, strong) ZNGCorrespondent* sender;
@property(nonatomic, strong) NSString* recipientType;
@property(nonatomic, strong) ZNGCorrespondent* recipient;
@property(nonatomic, strong) NSArray* attachments;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* readAt;
@property(nonatomic, assign) BOOL isDelayed;
@property(nonatomic, strong) NSDate * executeAt;
@property(nonatomic, strong) NSDate * executedAt;

/**
 *  If this is an inbound, this is the contact ID.  Outbound, it is the triggered by user ID.
 */
@property (nonatomic, readonly) NSString * senderPersonId;

#pragma mark - Properties added by containing Conversation
@property (nonatomic, copy) NSString * senderDisplayName;

/**
 *  KVO compliant dictionary that will be loaded with image data from attachments
 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> * imageAttachmentsByName;

/**
 *  Used only for transient outgoing message data objects.  This entire ZNGMessage object will be replaced once the server acknowledges the outbound message.
 */
@property (nonatomic, strong) NSArray<UIImage *> * outgoingImageAttachments;

/**
 *  If this message was sent from a service and has trigger-er information, that will be returned.  Otherwise, the sender ID will be returned.
 */
- (NSString *) triggeredByUserIdOrSenderId;

- (BOOL) isOutbound;

- (void) downloadAttachmentsIfNecessary;

/**
 *  The sender or receiver, whichever corresponds to a contact.
 */
- (ZNGCorrespondent *) contactCorrespondent;

@end
