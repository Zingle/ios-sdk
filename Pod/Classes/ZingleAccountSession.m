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
#import "ZNGConversationViewController.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGAutomationClient.h"
#import "ZNGContactClient.h"
#import "ZNGContactChannelClient.h"
#import "ZNGLabelClient.h"

static const int zngLogLevel = ZNGLogLevelInfo;

// Override readonly properties with strong properties to get proper KVO
@interface ZingleAccountSession ()

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, ZNGConversationServiceToContact *> * conversationsByContactId;

@end

@implementation ZingleAccountSession
{
    ZNGAccountChooser accountChooser;
    ZNGServiceChooser serviceChooser;
    
    ZNGAccount * _account;
    ZNGService * _service;
}



- (instancetype) initWithToken:(NSString *)token key:(nonnull NSString *)key
{
    return [self initWithToken:token key:key accountChooser:nil serviceChooser:nil];
}

- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key accountChooser:(nullable ZNGAccountChooser)anAccountChooser serviceChooser:(nullable ZNGServiceChooser)aServiceChooser
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        accountChooser = anAccountChooser;
        serviceChooser = aServiceChooser;
        _conversationsByContactId = [[NSMutableDictionary alloc] init];
        [self retrieveAvailableAccounts];
    }
    
    return self;
}


#pragma mark - Service/Account setters
- (void) setAccount:(ZNGAccount *)account
{
    if ((_account != nil) && (![_account isEqual:account])) {
        ZNGLogError(@"Account was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _account ,account);
        [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
        [self willChangeValueForKey:NSStringFromSelector(@selector(available))];
        _service = nil;
        _available = nil;
        [self didChangeValueForKey:NSStringFromSelector(@selector(available))];
        [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
    }
    
    _account = account;
    
    if (_account != nil) {
        [self updateStateForNewAccountOrService];
    }
}

- (ZNGAccount *)account
{
    if (_account != nil) {
        return _account;
    }
    
    if ([self.availableAccounts count] == 1) {
        return [self.availableAccounts firstObject];
    }
    
    return nil;
}

- (ZNGService *)service
{
    if (_service != nil) {
        return _service;
    }
    
    if ([self.availableServices count] == 1) {
        return [self.availableServices firstObject];
    }
    
    return nil;
}

- (void) setService:(ZNGService *)service
{
    if ((_service != nil) && (![_service isEqual:service])) {
        ZNGLogError(@"Service was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _service ,service);
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(available))];
    _available = (service != nil);
    _service = service;
    [self didChangeValueForKey:NSStringFromSelector(@selector(available))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
    
    if (_service != nil) {
        [self updateStateForNewAccountOrService];
    }
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
    if (self.account == nil) {
        if (self.availableAccounts == nil) {
            // We have no available accounts.  Go request them.
            [self retrieveAvailableAccounts];
        } else if (accountChooser != nil) {
            // We have just gotten a list of available accounts.
            
            // If there is anything in the list, we will ask our chooser to pick one
            if ([self.availableAccounts count] > 1) {
                self.account = accountChooser(self.availableAccounts);
            }
            
            accountChooser = nil;
        }
        return;
    }
    
    // Do we need to select a service?
    if (self.service == nil) {
        if (self.availableServices == nil) {
            // We have no available services.  Go request them.
            [self retrieveAvailableServices];
        } else if (serviceChooser != nil) {
            // We have just gotten a list of services
            
            // If there is anything in the list, we will ask our chooser to pick one
            if ([self.availableServices count] > 1) {
                self.service = serviceChooser(self.availableServices);
            }
            
            serviceChooser = nil;
        }
        return;
    }
    
    // We now have both an account and a service selected.
    
    [self initializeAllClients];
}

- (void) initializeAllClients
{
    NSString * serviceId = self.service.serviceId;
    
    self.automationClient = [[ZNGAutomationClient alloc] initWithSession:self serviceId:serviceId];
    self.contactChannelClient = [[ZNGContactChannelClient alloc] initWithSession:self serviceId:serviceId];
    self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
    self.labelClient = [[ZNGLabelClient alloc] initWithSession:self serviceId:serviceId];
    self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
    
    [self _registerForPushNotificationsForServiceIds:@[serviceId] removePreviousSubscriptions:YES];
}

#pragma mark - Account retrieval
- (void) retrieveAvailableAccounts
{
    [self.accountClient getAccountListWithSuccess:^(NSArray *accounts, ZNGStatus *status) {
        
        if ([accounts count] == 0) {
            self.availableAccounts = @[];   // This ensures that we will set our list explicitly to an empty array instead of just nil if there is no data
        } else {
            self.availableAccounts = accounts;
        }
        
        // Clear our services since we may have just picked a new account.
        self.availableServices = nil;
        
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableAccounts = @[];
        self.availableServices = nil;
    }];
}

#pragma mark - Service retrieval
- (void) retrieveAvailableServices
{
    [self.serviceClient serviceListUnderAccountId:self.account.accountId success:^(NSArray *services, ZNGStatus *status) {
        if ([services count] == 0) {
            self.availableServices = @[];
        } else {
            self.availableServices = services;
        }
        
        if ([services count] == 1) {
            self.service = [services firstObject];
        }
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableServices = nil;
    }];
}

#pragma mark - Messaging
- (ZNGConversationServiceToContact *) conversationWithContact:(ZNGContact *)contact;
{
    // Do we have a cached version of this conversation already?
    ZNGConversationServiceToContact * conversation = self.conversationsByContactId[contact.contactId];
    
    if (conversation == nil) {
        conversation = [[ZNGConversationServiceToContact alloc] initFromService:self.service toContact:contact withMessageClient:self.messageClient];
        self.conversationsByContactId[contact.contactId] = conversation;
    }

    [conversation updateMessages];
    return conversation;
}

- (ZNGConversationViewController *) conversationViewControllerForConversation:(ZNGConversation *)conversation
{
    if (conversation == nil) {
        ZNGLogError(@"Attempted to display view controller for a nil conversation.");
        return nil;
    }
    
    ZNGConversationViewController * vc = [[ZNGConversationViewController alloc] init];
    vc.conversation = conversation;
    return vc;
}

@end
