//
//  ZNGAnalytics.h
//  Pods
//
//  Created by Jason Neel on 8/30/16.
//
//

#import <Foundation/Foundation.h>

@class ZNGAutomation;
@class ZNGChannel;
@class ZNGContact;
@class ZNGContactField;
@class ZNGConversation;
@class ZNGConversationServiceToContact;
@class ZNGInboxDataSet;
@class ZNGLabel;
@class ZNGMessage;
@class ZNGTemplate;
@class ZNGUserAuthorization;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGAnalytics : NSObject

+ (instancetype) sharedAnalytics;

@property (nonatomic) BOOL enabled;

/**
 *  The key used to authenticate with Segment.
 */
@property (nonatomic, copy) NSString * segmentWriteKey;

/**
 *  Used to send the host name with all analytics meta data.
 */
@property (nonatomic, copy) NSURL * zingleURL;

#pragma mark - Login
- (void) trackLoginFailureWithToken:(NSString *)token;
- (void) trackLoginSuccessWithToken:(NSString *)token andUserAuthorizationObject:(ZNGUserAuthorization *)userAuthorization;

#pragma mark - Inbox
- (void) trackConversationFilterSwitch:(ZNGInboxDataSet *)inboxData;

#pragma mark - Conversation events
- (void) trackInsertedCustomField:(ZNGContactField *)customField intoConversation:(ZNGConversationServiceToContact * __nullable)conversation;
- (void) trackInsertedTemplate:(ZNGTemplate *)template intoConversation:(ZNGConversationServiceToContact * __nullable)conversation;
- (void) trackTriggeredAutomation:(ZNGAutomation *)automation onContact:(ZNGContact *)contact;
- (void) trackSentSavedImageToConversation:(ZNGConversation *)conversation;
- (void) trackSentCameraImageToConversation:(ZNGConversation *)conversation;
- (void) trackAddedNote:(NSString *)note toConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackSentMessage:(ZNGMessage *)message inConversation:(ZNGConversation *)conversation;
- (void) trackSentMessage:(NSString *)messageBody toContact:(ZNGContact *)contact;
- (void) trackSentMessage:(NSString *)messageBody toMultipleContacts:(NSArray<ZNGContact *> *)contacts;
- (void) trackSentMessage:(NSString *)messageBody toLabels:(NSArray<ZNGLabel *> *)labels;
- (void) trackSentMessage:(NSString *)messageBody toPhoneNumbers:(NSArray<NSString *> *)phoneNumbers;
- (void) trackChangedChannel:(ZNGChannel *)channel inConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackConfirmedConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackUnconfirmedConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackStarredContact:(ZNGContact *)contact;
- (void) trackUnstarredContact:(ZNGContact *)contact;
- (void) trackShowedConversationDetails:(ZNGConversationServiceToContact *)conversation;
- (void) trackHidConversationDetails:(ZNGConversationServiceToContact *)conversation;

#pragma mark - Contact management
- (void) trackCreatedContact:(ZNGContact *)contact;
- (void) trackEditedExistingContact:(ZNGContact *)contact;
- (void) trackAddedLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact;
- (void) trackRemovedLabel:(ZNGLabel *)label fromContact:(ZNGContact *)contact;

NS_ASSUME_NONNULL_END


@end
