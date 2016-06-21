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
#import "ZNGConversationViewController.h"

static const int zngLogLevel = ZNGLogLevelInfo;

// Override readonly properties with strong properties to get proper KVO
@interface ZingleAccountSession ()

@property (nonatomic, strong, nullable) NSDictionary<NSString *, ZNGConversation *> * conversationsByContactId;

@end

@implementation ZingleAccountSession
{
    ZingleSpecificAccountSession * privateSession; // The session object that handles the actual session once the user has chosen an account and a service.
    
    ZNGAccountChooser accountChooser;
    ZNGServiceChooser serviceChooser;
    
    ZNGAccount * _account;
    ZNGService * _service;
}

- (instancetype) initWithToken:(NSString *)token key:(nonnull NSString *)key
{
    return [self initWithToken:token key:key accountChooser:nil serviceChooser:nil];
}

- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key accountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
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
    [self updateStateForNewAccountOrService];
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
    _available = (_service != nil);
    _service = service;
    [self didChangeValueForKey:NSStringFromSelector(@selector(available))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
    
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
    if (self.service == nil) {
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
    if (self.account == nil) {
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
    
    // Setup our proxy object to handle all requests.
    privateSession = [[ZingleSpecificAccountSession alloc] initWithAccountSession:self account:self.account service:self.service];
}

- (BOOL) shouldForwardInvocations
{
    // Invocations will only be forwarded to our private proxy object if the user has selected a service and an account.
    return ((self.service != nil) && (self.account != nil));
}

#pragma mark - Proxying
- (BOOL) respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    
    return ([privateSession respondsToSelector:aSelector]);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature * signature = [privateSession methodSignatureForSelector:aSelector];
    
    if (([self shouldForwardInvocations]) && (signature != nil)) {
        return signature;
    }
    
    return [super methodSignatureForSelector:aSelector];
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
    } failure:^(ZNGError *error) {
        self.availableServices = nil;
    }];
}

#pragma mark - Messaging
- (ZNGConversation *) conversationWithContact:(ZNGContact *)contact;
{
    // Do we have a cached version of this conversation already?
    ZNGConversation * conversation = self.conversationsByContactId[contact.contactId];
    
    if (conversation != nil) {
        // Ensure the conversation has a reference to us for communication.  This is 99% redundant and can be removed.
        conversation.messageClient = self.messageClient;
        
        // Ask the conversation to update itself as it is being delivered
        [conversation updateMessages];
        
        return conversation;
    }
    
    // We do not have this conversation locally.  It is either a brand new conversation or it has not yet been retrieved from the server.
    // Either way, we are making a new conversation object.  It will initialize itself as empty if no communicaiton has taken place previously.
    ZNGChannel * channel = [contact channelForFreshOutgoingMessage];
    
    if (channel == nil) {
        ZNGLogWarn(@"Unable to pick a default outgoing channel for %@ (%@).  Unable to create conversation.", [contact fullName], contact.contactId);
    }
    
    ZNGChannelType * channelType = channel.channelType;
    ZNGChannel * serviceChannel = [self.service defaultChannelForType:channelType];

    conversation = [[ZNGConversation alloc] init];
    conversation.session = self;
    conversation.contact = contact;
    conversation.channelType = channelType;
    conversation.contactChannelValue = channel.value;
    conversation.serviceChannelValue = serviceChannel.value;
    conversation.serviceId = self.service.serviceId;
    conversation.contactId = contact.contactId;
    conversation.toService = NO;
    
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
