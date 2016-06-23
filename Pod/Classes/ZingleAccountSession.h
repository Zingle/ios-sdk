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
@class ZNGAutomationClient, ZNGContactChannelClient, ZNGContactClient, ZNGLabelClient, ZNGMessageClient, ZNGTemplateClient;
@class ZNGConversationViewController;

@interface ZingleAccountSession : ZingleSession

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

#pragma mark - Clients
@property (nonatomic, strong, nonnull) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nonnull) ZNGContactChannelClient * contactChannelClient;
@property (nonatomic, strong, nonnull) ZNGLabelClient * labelClient;
@property (nonatomic, strong, nonnull) ZNGTemplateClient * templateClient;

#pragma mark - Status
/**
 *  KVO compliant flag that indicates when the session has been fully initialized (with an account and a service) and may take requests.
 */
@property (nonatomic, assign) BOOL available;

#pragma mark - Initialization
/**
 *  Constructor for a Zingle account-level session object.  Includes optional parameters which may be used to provide callbacks to select
 *   an account and service if more than one of either is available.  These blocks will be unused and dealloced if there is only one account
 *   or service.
 *
 *  The block parameters will be called a maximum of one time and will be dealloced after being called or after they are deemed unnecessary (e.g.
 *   we got our list of available accounts, and there is only one available account; we have no need for the account chooser callback.)
 *
 *  These blocks are free to return nil.  If they return nil, someone must set or account and service properties later.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 *  @param accountChooser The optional block which will be called and asked for a choice of account if multiple accounts are available to this user
 *  @param serviceChooser The optional block which will be called and asked for a choice of service if multiple services are available to this user
 */
- (instancetype) initWithToken:(NSString *)token key:(NSString *)key accountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser;

/**
 *  Initializer for a Zingle session object.  If this constructor is used to create a ZingleAccountSession, the caller is later responsible for selecting an account
 *   and service if two or more of either exist for this account.  They will be available in the availableAccounts and availableServices KVO-compliant properties.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 */
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key;

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

- (ZNGConversationViewController *) conversationViewControllerForConversation:(ZNGConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
