//
//  ZingleAccountSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"
#import "ZingleSDK.h"

NS_ASSUME_NONNULL_BEGIN
@class ZNGService;
@class ZNGAccount;
@class ZNGChannelType;
@class ZNGContact;
@class ZNGConversationServiceToContact;
@class ZNGAutomationClient, ZNGContactClient, ZNGLabelClient, ZNGMessageClient;
@class ZNGServiceToContactViewController;
@class ZNGContactEditViewController;
@class ZNGUserAuthorization;
@class ZNGUserClient;

/**
 *  Notification name posted with an NSNumber bool as the object when the user switches to or from detailed event viewing
 */
extern NSString * const ZingleUserChangedDetailedEventsPreferenceNotification;

@interface ZingleAccountSession : ZingleSession <NSCacheDelegate>

#pragma mark - Account/Service selection
/**
 *  All accounts available to this user.  This array will be set to an empty array @[] if a response has arrived from the server
 *   that does not contain any accounts.
 */
@property (nonatomic, readonly, nullable) NSArray<ZNGAccount *> * availableAccounts;

/**
 *  All services that are available to the current acount.  This array will be set to an empty array @[] if a response has arrived
 *   from the server that does not contain any services.
 */
@property (nonatomic, readonly, nullable) NSArray<ZNGService *> * availableServices;

/**
 *  The current account.  This may be set to any value in availableAccounts.  Setting it multiple times has undefined behavior.
 */
@property (nonatomic, strong, nullable) ZNGAccount * account;

/**
 *  The current service.  This may be set to any value in availableServices.  Setting it multiple times has undefined behavior.
 */
@property (nonatomic, strong, nullable) ZNGService * service;

/**
 *  Meta data about the current user.
 */
@property (nonatomic, strong, nullable) ZNGUserAuthorization * userAuthorization;
@property (nonatomic, strong, nullable) ZNGUser * user;

/**
 *  If set, the service object will be refreshed whenever returning from the background (but no more often than every ten minutes.)
 *
 *  Defaults to YES.
 */
@property (nonatomic, assign) BOOL automaticallyUpdateServiceWhenReturningFromBackground;

/**
 *  The block called if multiple accounts exist on connection.
 *
 *  This is set to nil after initial connection.
 */
@property (nonatomic, copy, nullable) ZNGAccountChooser accountChooser;

/**
 *  The block called if multiple services exist on connection.
 *
 *  This is set to nil after initial connection.
 */
@property (nonatomic, copy, nullable) ZNGServiceChooser serviceChooser;

/**
 *  Completion block called once connecting succeeds or fails.  This will be set to nil after a connection success or failure.
 */
@property (nonatomic, copy, nullable) ZNGAccountSessionCallback completion;

#pragma mark - Clients
@property (nonatomic, strong, nullable) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nullable) ZNGLabelClient * labelClient;
@property (nonatomic, strong, nullable) ZNGUserClient * userClient;

/**
 *  If this flag is set, all conversation objects provided by this session will be detailed event conversations.
 */
@property (nonatomic, assign) BOOL showDetailedEvents;

#pragma mark - Initialization
- (id) initWithToken:(NSString *)token key:(NSString *)key;

- (void) connect;

- (void) connectWithCompletion:(nullable ZNGAccountSessionCallback)completion;

- (void) connectWithAccountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser completion:(nullable ZNGAccountSessionCallback)completion;

#pragma mark - User data
- (void) updateUserData;

#pragma mark - Messaging methods

/**
 *  Retrieves a conversation between the current service and the specified contact.
 *
 *  If no such conversation yet exists in our data, a blank conversation will be returned.  It will populate itself
 *   as soon as a network request returns.
 *
 *  @param contactId The identifier for the desired contact
 */
- (ZNGConversationServiceToContact *) conversationWithContact:(ZNGContact *)contact;

/**
 *  Asynchronous retrieval of contact information.  Using conversationWithContact: is preferred if the ZNGContact object is available.
 *  This is used most commonly to display a conversation just after launch, in response to a push notification.
 */
- (void) conversationWithContactId:(NSString *)contactId completion:(void (^)(ZNGConversationServiceToContact * _Nullable))completion;

- (ZNGServiceToContactViewController *) conversationViewControllerForConversation:(ZNGConversationServiceToContact *)conversation;

/**
 *  Returns a modal view controller for creating a new contact.  This view will dismiss itself when appropriate.
 */
- (ZNGContactEditViewController *) contactEditViewControllerForNewContact;

/**
 *  Send a message to multiple recipients.  This can be used to send to a single recipient, but it is prefered to use a ZNGConversation object in order to 
 *   track and display messages in UI.
 *
 *  At least one value must be present in the contacts, labels, or phoneNumbers arrays.
 */
- (void) sendMessage:(NSString *)body withUUID:(nullable NSString *)uuid toContacts:(NSArray<ZNGContact *> *)contacts labels:(NSArray<ZNGLabel *> *)labels phoneNumbers:(NSArray<NSString *> *)phoneNumbers completion:(void (^_Nullable)(BOOL succeeded))completion;

@end

NS_ASSUME_NONNULL_END
