//
//  ZingleAccountSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleAccountSession.h"
#import "ZNGLogging.h"
#import "ZNGAccount.h"
#import "ZNGService.h"
#import "ZNGAccountClient.h"
#import "ZNGServiceClient.h"
#import "ZingleSpecificAccountSession.h"

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZingleAccountSession
{
    ZingleSpecificAccountSession * privateSession; // The session object that handles the actual session once the user has chosen an account and a service.
    ZNGAccountClient * accountClient;
    ZNGServiceClient * serviceClient;
}

- (instancetype) initWithToken:(NSString *)token key:(nonnull NSString *)key
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        accountClient = [[ZNGAccountClient alloc] init];
        [self retrieveAvailableAccounts];
    }
    
    return self;
}

#pragma mark - Service/Account setters
- (void) setAccount:(ZNGAccount *)account
{
    if ((_account != nil) && (![_account isEqual:account])) {
        ZNGLogError(@"Account was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _account ,account);
    }
    
    _account = account;
    [self updateStateForNewAccountOrService];
}

- (void) setService:(ZNGService *)service
{
    if ((_service != nil) && (![_service isEqual:service])) {
        ZNGLogError(@"Service was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _service ,service);
    }
    
    _service = service;
    [self updateStateForNewAccountOrService];
}

- (void) setAvailableAccounts:(NSArray<ZNGAccount *> * _Nullable)availableAccounts
{
    _availableAccounts = availableAccounts;
}

- (void) setAvailableServices:(NSArray<ZNGService *> * _Nullable)availableServices
{
    _availableServices = availableServices;
}

#pragma mark - Account/Service state management
- (void) updateStateForNewAccountOrService
{
    // Do we need to select an account?
    if (![self hasSelectedAccount]) {
        [self retrieveAvailableAccounts];
        return;
    }
    
    // Do we need to select a service?
    if (![self hasSelectedService]) {
        [self retrieveAvailableServices];
        return;
    }
    
    // We now have both an account and a service selected.
    
    // Setup our proxy object to handle all requests.
    privateSession = [[ZingleSpecificAccountSession alloc] initWithToken:self.token key:self.key account:self.account service:self.service];
}

- (BOOL) hasSelectedAccount
{
    // Either we have one and only one account available or they have selected one.
    return (([self.availableAccounts count] == 1) || (self.account != nil));
}

- (BOOL) hasSelectedService
{
    // Either we have one and only one service available or they have selected one.
    return (([self.availableServices count] == 1) || (self.service != nil));
}

- (BOOL) shouldForwardInvocations
{
    // Invocations will only be forwarded to our private proxy object if the user has selected a service and an account.
    return (([self hasSelectedService]) && ([self hasSelectedAccount]));
}

#pragma mark - Proxying
- (BOOL) respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    
    return ([privateSession respondsToSelector:aSelector]);
}

- (void) forwardInvocation:(NSInvocation *)anInvocation
{
    if ([privateSession respondsToSelector:anInvocation.selector]) {
        
        if ([self shouldForwardInvocations]) {
            [anInvocation invokeWithTarget:privateSession];
        } else {
            ZNGLogError(@"%@ was called on %@ before an account and/or session was selected.  Ignoring request.", NSStringFromSelector(anInvocation.selector), [self class]);
            return;
        }
    } else {
        [super forwardInvocation:anInvocation];
    }
}

#pragma mark - Account retrieval
- (void) retrieveAvailableAccounts
{
    [accountClient getAccountListWithSuccess:^(NSArray *accounts, ZNGStatus *status) {
        self.availableAccounts = accounts;
        self.availableServices = nil;
        
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableAccounts = nil;
        self.availableServices = nil;
    }];
}

#pragma mark - Service retrieval
- (void) retrieveAvailableServices
{
    serviceClient = [[ZNGServiceClient alloc] initWithAccount:self.account];
    [serviceClient serviceListWithSuccess:^(NSArray *services, ZNGStatus *status) {
        self.availableServices = services;
    } failure:^(ZNGError *error) {
        self.availableServices = nil;
    }];
}

@end
