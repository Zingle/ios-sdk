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
@class ZNGServiceToContactViewController;

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
 *  @param accountChooser The optional block which will be called and asked for a choice of account if multiple (or zero) accounts are available to this user
 *  @param serviceChooser The optional block which will be called and asked for a choice of service if multiple (or zero) services are available to this user
 *  @param errorHandler Optional block that is called every time an error is received.
 */
- (instancetype) initWithToken:(NSString *)token
                           key:(NSString *)key
                accountChooser:(nullable ZNGAccountChooser)accountChooser
                serviceChooser:(nullable ZNGServiceChooser)serviceChooser
                  errorHandler:(nullable ZNGErrorHandler)errorHandler NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key errorHandler:(nullable ZNGErrorHandler)errorHandler NS_UNAVAILABLE;

/**
 *  To be called if the user specifically logs out (vs. just changing account or service.)  This will unregister for push notifications.
 */
- (void) logout;

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
 *  Send a message to multiple recipients.  This can be used to send to a single recipient, but it is prefered to use a ZNGConversation object in order to 
 *   track and display messages in UI.
 *
 *  At least one value must be present in the contacts, labels, or phoneNumbers arrays.
 */
- (void) sendMessage:(NSString *)body toContacts:(NSArray<ZNGContact *> *)contacts labels:(NSArray<ZNGLabel *> *)labels phoneNumbers:(NSArray<NSString *> *)phoneNumbers completion:(void (^_Nullable)(BOOL succeeded))completion;

@end

NS_ASSUME_NONNULL_END
