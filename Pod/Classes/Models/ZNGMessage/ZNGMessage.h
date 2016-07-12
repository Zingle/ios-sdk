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

@interface ZNGMessage : MTLModel<MTLJSONSerializing, JSQMessageData, JSQMessageMediaData>

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

@property (nonatomic, strong) UIImage * image;

#pragma mark - Properties added by containing Conversation
@property (nonatomic, copy) NSString * senderDisplayName;

/**
 *  If this message was sent from a service and has trigger-er information, that will be returned.  Otherwise, the sender ID will be returned.
 */
- (NSString *) triggeredByUserIdOrSenderId;

- (BOOL) isOutbound;

- (void) downloadAttachmentsIfNecessary;

@end
