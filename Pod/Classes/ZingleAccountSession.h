//
//  ZingleAccountSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"

@class ZNGService;
@class ZNGAccount;
@class ZNGAccountClient;
@class ZNGServiceClient;
@class ZNGAutomationClient;

typedef ZNGAccount * _Nullable (^ZNGAccountChooser)(NSArray<ZNGAccount *> * _Nonnull availableAccounts);
typedef ZNGService * _Nullable (^ZNGServiceChooser)(NSArray<ZNGService *> * _Nonnull availableServices);

@interface ZingleAccountSession : ZingleSession

#pragma mark - Account/Service selection
/*
 *  All accounts available to this user.  This array will be set to an empty array @[] if a response has arrived from the server
 *   that does not contain any accounts.
 */
@property (nonatomic, readonly, nullable) NSArray<ZNGAccount *> * availableAccounts;

/*
 *  All services that are available to the current acount.  This array will be set to an empty array @[] if a response has arrived
 *   from the server that does not contain any services.
 */
@property (nonatomic, readonly, nullable) NSArray<ZNGService *> * availableServices;

/*
 *  The current account.  This may be set to any value in availableAccounts.  Setting it multiple times has undefined behavior.
 */
@property (nonatomic, strong, nullable) ZNGAccount * account;

/*
 *  The current service.  This may be set to any value in availableServices.  Setting it multiple times has undefined behavior.
 */
@property (nonatomic, strong, nullable) ZNGService * service;

#pragma mark - Status
/*
 *  KVO compliant flag that indicates when the session has been fully initialized (with an account and a service) and may take requests.
 */
@property (nonatomic, assign) BOOL available;

#pragma mark - Clients
/*
 *  The client used to retrieve ZNGAccount information
 */
@property (nonatomic, readonly, nullable) ZNGAccountClient * accountClient;

/*
 *  The client used to retrieve ZNGService information
 */
@property (nonatomic, readonly, nullable) ZNGServiceClient * serviceClient;

#pragma mark - Initialization
/*
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
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key accountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser;

@end

/*
 *  The methods and property get/set methods in this category will generate a logged error and have no effect if they are called before the 'available' flag is set
 *  i.e. they cannot be called until we have a specific account and service selected
 */
@interface ZingleAccountSession (MethodsRequiringAuthentication)

@property (nonatomic, readonly, nullable) ZNGAutomationClient * automationClient;

@end
