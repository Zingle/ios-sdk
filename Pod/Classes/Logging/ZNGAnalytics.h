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

@interface ZNGAnalytics : NSObject

+ (instancetype) sharedAnalytics;

@property (nonatomic, copy) NSString * segmentWriteKey;

#pragma mark - Login
- (void) trackLoginFailureWithToken:(NSString *)token;
- (void) trackLoginSuccessWithToken:(NSString *)token;

#pragma mark - Inbox
- (void) trackConversationFilterSwitch:(ZNGInboxDataSet *)inboxData;

#pragma mark - Conversation events
- (void) trackInsertedCustomField:(ZNGContactField *)customField intoConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackInsertedTemplate:(ZNGTemplate *)template intoConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackTriggeredAutomation:(ZNGAutomation *)automation onContact:(ZNGContact *)contact;
- (void) trackSentSavedImageToConversation:(ZNGConversation *)conversation;
- (void) trackSentCameraImageToConversation:(ZNGConversation *)conversation;
- (void) trackAddedNote:(NSString *)note toConversation:(ZNGConversationServiceToContact *)conversation;
- (void) trackSentMessage:(ZNGMessage *)message inConversation:(ZNGConversation *)conversation;
- (void) trackChangedChannel:(ZNGChannel *)channel inConversation:(ZNGConversationServiceToContact *)conversation;
- (void) confirmedConversation:(ZNGConversationServiceToContact *)conversation;
- (void) unconfirmedConversation:(ZNGConversationServiceToContact *)conversation;
- (void) starredContact:(ZNGContact *)contact;
- (void) unstarredContact:(ZNGContact *)contact;
- (void) showedConversationDetails:(ZNGConversationServiceToContact *)conversation;
- (void) hidConversationDetails:(ZNGConversationServiceToContact *)conversation;

#pragma mark - Contact management
- (void) trackCreatedContact:(ZNGContact *)contact;
- (void) trackEditedExistingContact:(ZNGContact *)contact;
- (void) trackAddedLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact;




@end
