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
@class ZNGNetworkLookout;
@class ZNGInboxStatistician;
@class ZNGTeamClient;
@class ZNGAssignmentViewController;
@class ZNGNotificationSettingsClient;
@class ZNGUserV2;

/**
 *  Notification name posted with an NSNumber bool as the object when the user switches to or from detailed event viewing
 */
extern NSString * const ZingleUserChangedDetailedEventsPreferenceNotification;

/**
 *  Notification posted whenever new message/event data is detected through an asynchronous connection.
 *  Conversation objects do *not* automatically refresh.  UI displaying a conversation should trigger a refresh
 *   when receiving this notification.
 *
 *  `userData[ZingleConversationNotificationContactIdKey]` will contain the UUID of the conversation.
 */
extern NSString * const ZingleConversationDataArrivedNotification;
extern NSString * const ZingleConversationNotificationContactIdKey;

/**
 *  Notification posted when feed/conversation lists should be refreshed.  Maybe a contact was deleted.  Maybe a segment changed.
 *  All we know is that the world is now somehow different.
 */
extern NSString * const ZingleFeedListShouldBeRefreshedNotification;

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
 *  Flag that is set if the current user has ever been authenticated.  This can be used to handle auth failures differently on
 *   initial login vs. one that happens later in the session.  This differs from the `available` flag in that it is set before
 *   the login has fully completed.
 */
@property (nonatomic, assign) BOOL userHasBeenAuthenticated;

/**
 *  Meta data about the current user.
 */
@property (nonatomic, strong, nullable) ZNGUserAuthorization * userAuthorization;

/**
 *  YES if the current user has access to one or more HIPAA services. Note that the current service may or
 *  may not itself be a HIPAA service.
 */
@property (readonly) BOOL userHasHipaaAccess;

/**
 *  How long is this user allowed to be idle before requiring re-authentication? `0.0` indicates no idle time limit.
 *  This is generally 20 minutes for HIPAA users and `0.0` otherwise.
 */
@property (readonly) NSTimeInterval idleTimeLimit;

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

/**
 *  All users in the current service.  Each ZNGUser object includes online status.
 *  As of March 2020, this data may be incomplete vs. the old V1 API user data as found in `userAuthorization`.
 */
@property (nonatomic, strong, nullable) NSArray<ZNGUser *> * users;

/**
 *  Online user status, externally set by the socket client.
 *  Prefer using `usersIncludingSelf:`, `usersOnCommonTeamsIncludingSelf:`, etc. to get this data vs. consulting this property.
 *  Those methods will include accurate `isOnline` flags for each user.
*/
@property (nonatomic, strong) NSSet<NSString *> * onlineUserIds;

/**
 *  The manager of all inbox count data.
 */
@property (nonatomic, strong, nullable) ZNGInboxStatistician * inboxStatistician;

/**
 *  The total number of unread conversations relevant to this user.  This should always match the badge number sent in push notifications.
 */
@property (nonatomic, assign) NSUInteger totalUnreadCount;

#pragma mark - Clients
@property (nonatomic, strong, nullable) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nullable) ZNGLabelClient * labelClient;
@property (nonatomic, strong, nullable) ZNGUserClient * userClient;
@property (nonatomic, strong, nullable) ZNGNotificationSettingsClient * notificationSettingsClient;

#pragma mark - Network diagnostics
@property (nonatomic, strong, nullable) ZNGNetworkLookout * networkLookout;

/**
 *  If this flag is set, all conversation objects provided by this session will be detailed event conversations.
 */
@property (nonatomic, assign) BOOL showDetailedEvents;

#pragma mark - Initialization
- (id) initWithToken:(NSString *)token key:(NSString *)key;

- (id) initWithJWT:(NSString *)jwt;

- (void) connect;

- (void) connectWithCompletion:(nullable ZNGAccountSessionCallback)completion;

- (void) connectWithAccountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser completion:(nullable ZNGAccountSessionCallback)completion;

#pragma mark - Data
- (void) updateUserData;

/**
 *  Refreshes the current service object
 */
- (void) updateCurrentService;

#pragma mark - External data
/**
 *  If a contact data change is detected elsewhere, such as through the /contacts/ end point somewhere else,
 *   calling this method ensures that any cached data for that contact (such as within conversations) is updated.
 */
- (void) contactChanged:(ZNGContact *)contact;

#pragma mark - Push notifications
/**
 *  Asks the server to send a push notification.  Can be used to test pushes from top to bottom by listening for a ZNGPushNotificationReceived notification.
 */
- (void) requestAPushNotification;

#pragma mark - Teams
/**
 *  The teams visible to the current user.  Generally, this returns only teams of which the current user is a member.  Admin
 *   users will see all teams.
 */
- (NSArray<ZNGTeam *> * _Nonnull) teamsVisibleToCurrentUser;

/**
 *  Teams to which the specified user belongs.
 */
- (NSArray<ZNGTeam *> * _Nonnull) teamsToWhichUserBelongsWithId:(NSString * _Nonnull)userId;

/**
 *  For non-admin users, this will be identicial to `teamsVisibleToCurrentUser`
 */
- (NSArray<ZNGTeam *> * _Nonnull) teamsToWhichCurrentUserBelongs;

/**
 *  If includeSelf is YES, the return value is identical to the `users` getter.
 */
- (NSArray<ZNGUser *> * _Nonnull) usersIncludingSelf:(BOOL)includeSelf;

/**
 *  Returns only users that share at least one team with the current user.
 *  Includes the current user if `includeSelf` is YES.
 *  Returns @[] if team assignment is not enabled on the service.
 */
- (NSArray<ZNGUser *> * _Nonnull) usersOnCommonTeamsIncludingSelf:(BOOL)includeSelf;

/**
 *  The user with the provided UUID, if available
 */
- (ZNGUser * _Nullable) userWithId:(NSString *)userId;


#pragma mark - Messaging methods

/**
 *  Retrieves a conversation between the current service and the specified contact.
 *
 *  If no such conversation yet exists in our data, a blank conversation will be returned.  It will populate itself
 *   as soon as a network request returns.
 *
 *  @param contact The desired contact
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
 *  Returns a modal view controller used to assign the provided contact.
 *  Note that the assignment delegate will need to be manually set for this view to accomplish anything.
 */
- (ZNGAssignmentViewController *) assignmentViewControllerForContact:(ZNGContact *)contact;

/**
 *  Send a message to multiple recipients.  This can be used to send to a single recipient, but it is prefered to use a ZNGConversation object in order to 
 *   track and display messages in UI.
 *
 *  At least one value must be present in the contacts, labels, groups, or phoneNumbers arrays.
 */
- (void) sendMessage:(nullable NSString *)body
 imageAttachmentData:(nullable NSArray<NSData *> *)attachments
            withUUID:(nullable NSString *)uuid
          toContacts:(nullable NSArray<ZNGContact *> *)contacts
              labels:(nullable NSArray<ZNGLabel *> *)labels
              groups:(nullable NSArray<ZNGContactGroup *> *)groups
        phoneNumbers:(nullable NSArray<NSString *> *)phoneNumbers
          completion:(void (^_Nullable)(BOOL succeeded))completion;

@end

NS_ASSUME_NONNULL_END
