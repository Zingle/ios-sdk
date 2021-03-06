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
@class ZNGContactGroup;
@class ZNGMessage;
@class ZNGTeam;
@class ZNGTemplate;
@class ZNGUser;
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
- (void) trackLoginFailure;
- (void) trackLoginSuccessWithToken:(NSString *)token andUserAuthorizationObject:(ZNGUserAuthorization *)userAuthorization;

#pragma mark - Inbox
- (void) trackConversationFilterSwitch:(ZNGInboxDataSet *)inboxData;
- (void) trackSelectedInboxSortNewest;
- (void) trackSelectedInboxSortOldest;
- (void) trackSelectedInboxSortCustomField:(NSString *)fieldId;
- (void) trackToggledOpenFilter:(BOOL)open;
- (void) trackToggledUnreadFilter:(BOOL)unread;

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
- (void) trackSentMessage:(NSString *)messageBody toGroups:(NSArray<ZNGContactGroup *> *)groups;
- (void) trackSentMessage:(NSString *)messageBody toPhoneNumbers:(NSArray<NSString *> *)phoneNumbers;
- (void) trackChangedChannel:(ZNGChannel *)channel inConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackConfirmedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
- (void) trackUnconfirmedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
- (void) trackOpenedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
- (void) trackClosedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
- (void) trackShowedConversationDetails:(ZNGConversationServiceToContact *)conversation;
- (void) trackHidConversationDetails:(ZNGConversationServiceToContact *)conversation;

#pragma mark - Contact management
- (void) trackCreatedContact:(ZNGContact *)contact;
- (void) trackEditedExistingContact:(ZNGContact *)contact;
- (void) trackAddedLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact;
- (void) trackRemovedLabel:(ZNGLabel *)label fromContact:(ZNGContact *)contact;
- (void) trackContactUnassigned:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
- (void) trackContact:(ZNGContact *)contact assignedToTeam:(ZNGTeam *)team fromUIType:(nullable NSString *)sourceType;
- (void) trackContact:(ZNGContact *)contact assignedToUser:(ZNGUser *)user fromUIType:(nullable NSString *)sourceType;

#pragma mark - Easter eggs
- (void) trackEasterEggNamed:(NSString *)eggName;

NS_ASSUME_NONNULL_END


@end
