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

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZingleAccountSession
{
    ZingleSession * privateSession; // The session object that handles the actual session once the user has chosen an account and a service.
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
    // TODO: Retrieve account info
}

#pragma mark - Service retrieval
- (void) retrieveAvailableServices
{
    // TODO: Retrieve service info
}

@end
