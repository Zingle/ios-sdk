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
@property(nonatomic, strong) NSString* triggeredByUserId;
@property(nonatomic, strong) ZNGUser* triggeredByUser;
@property(nonatomic, strong) NSString* templateId;
@property(nonatomic, strong) NSString* senderType;
@property(nonatomic, strong) ZNGCorrespondent* sender;
@property(nonatomic, strong) NSString* recipientType;
@property(nonatomic, strong) ZNGCorrespondent* recipient;
@property(nonatomic, strong) NSArray* attachments;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* readAt;

/**
 *  Flag indicating that this message is being sent but does not yet exist on the server
 */
@property (nonatomic) BOOL sending;

#pragma mark - Properties added by containing Conversation
@property (nonatomic, copy) NSString * senderDisplayName;

/**
 *  KVO compliant array that will be loaded with image data from attachments
 */
@property (nonatomic, strong) NSArray<UIImage *> * imageAttachments;

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

/**
 *  An attributed string containing the body text plus any image attachments or loading image placeholders
 */
- (NSAttributedString *) attributedText;

@end
