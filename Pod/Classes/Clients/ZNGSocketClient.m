//
//  ZNGSocketClient.m
//  Pods
//
//  Created by Jason Neel on 12/15/16.
//
//

#import "ZNGSocketClient.h"
#import "ZNGLogging.h"
#import "ZingleSession.h"
#import <AFNetworking/AFNetworking.h>
#import "NSURL+Zingle.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGConversationContactToService.h"
#import "ZingleAccountSession.h"
#import "ZNGUserAuthorization.h"
@import SocketIO;

#if DEBUG
static const int zngLogLevel = ZNGLogLevelVerbose;
#else
static const int zngLogLevel = ZNGLogLevelWarning;
#endif

@implementation ZNGSocketClient
{
    SocketIOClient * socketClient;
    
    NSString * authPath;
    NSString * nodePath;
    
    // YES if we are currently waiting on our initial auth request
    BOOL initializingSession;
    
    // YES if we have completed an auth request and set our session cookies
    BOOL authSucceeded;
}

- (id) initWithSession:(ZingleSession *)session
{
    self = [super init];
    
    if (self != nil) {
        _session = session;
        
        NSString * zinglePrefix = [session.sessionManager.baseURL zingleServerPrefix];
        
        if (zinglePrefix == nil) {
            ZNGLogWarn(@"ZingleSession's base URL of %@ does not appear to be a Zingle URL.  Using production Zingle URL.", session.sessionManager.baseURL);
        }
        
        if ([zinglePrefix length] > 0) {
            authPath = [NSString stringWithFormat:@"https://%@-secure.zingle.me/", zinglePrefix];
            nodePath = [NSString stringWithFormat:@"https://%@-node.zingle.me:8000", zinglePrefix];
        } else {
            authPath = @"https://secure.zingle.me/";
            nodePath = @"https://node.zingle.me";
        }
    }
    
    return self;
}

- (BOOL) active
{
    return ((socketClient.status == SocketIOClientStatusConnected) || (socketClient.status == SocketIOClientStatusConnecting) || (initializingSession));
}

- (BOOL) connected
{
    return (socketClient.status == SocketIOClientStatusConnected);
}

- (void) setActiveConversation:(ZNGConversation *)activeConversation
{
    _activeConversation = activeConversation;
    [self subscribeForFeedUpdatesForConversation:activeConversation];
}

#pragma mark - Actions
- (void) connect
{
    if (authSucceeded) {
        // We already have our session data
        [self _connectSocket];
    } else {
        [self _authenticateAndConnect];
    }
}

- (void) _authenticateAndConnect
{
    ZNGLogVerbose(@"Request session cookie through a POST...");
    
    if (initializingSession) {
        ZNGLogDebug(@"Already starting connection.  Ignoring call to %s", __func__);
    }
    
    authSucceeded = NO;
    initializingSession = YES;
    
    NSURL * url = [NSURL URLWithString:authPath];
    
    AFHTTPSessionManager * session = [ZingleSession anonymousSessionManagerWithURL:url];
    [session.requestSerializer setAuthorizationHeaderFieldWithUsername:self.session.token password:self.session.key];
    session.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [session POST:@"auth" parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        ZNGLogDebug(@"Auth request succeeded.");
        authSucceeded = YES;
        [self _connectSocket];
        initializingSession = NO;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        initializingSession = NO;
        
        if (error != nil) {
            ZNGLogWarn(@"Error sending request to auth URL: %@", error.localizedDescription);
            return;
        }
        
        ZNGLogWarn(@"Request to auth at %@ failued for an unknown reason.", authPath);
    }];
}

- (void) _connectSocket
{
    NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:authPath]];
    ZNGLogVerbose(@"Copying %llu cookies from our auth connection to the web socket connection", (unsigned long long)[cookies count]);
    
#if DEBUG
    NSNumber * log = @YES;
#else
    NSNumber * log = @NO;
#endif
    
    socketClient = [[SocketIOClient alloc] initWithSocketURL:[NSURL URLWithString:nodePath] config:@{ @"cookies" : cookies, @"log" : log }];
    
    __weak ZNGSocketClient * weakSelf = self;
    
    [socketClient onAny:^(SocketAnyEvent * _Nonnull event) {
        [weakSelf socketEvent:event];
    }];
    
    [socketClient on:@"connect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidConnectWithData:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"feedLocked" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf feedLocked:data];
    }];
    
    [socketClient on:@"feedUnlocked" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf feedUnlocked:data];
    }];
    
    [socketClient on:@"nodeControllerBindSuccess" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidBindNodeController];
    }];
    
    [socketClient on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidEncounterErrorWithData:data];
    }];
    
    [socketClient on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidDisconnect];
    }];
    
    [socketClient connect];
}

- (void) disconnect
{
    [socketClient disconnect];
}

- (void) subscribeForFeedUpdatesForConversation:(ZNGConversation *)conversation
{
    if (![self connected]) {
        // We're not yet connected.  We will subscribe to an active conversation as soon as we connect.
        ZNGLogVerbose(@"%@ was called, but we are not yet connected.  Delaying subscription until a successful connection.", NSStringFromSelector(_cmd));
        return;
    }
    
    id feedId = [NSNull null];
    
    if ([conversation isKindOfClass:[ZNGConversationServiceToContact class]]) {
        ZNGConversationServiceToContact * contactConversation = (ZNGConversationServiceToContact *)conversation;
        feedId = contactConversation.contact.contactId;
    } else if ([conversation isKindOfClass:[ZNGConversationContactToService class]]) {
        ZNGConversationContactToService * serviceConversation = (ZNGConversationContactToService *)conversation;
        feedId = serviceConversation.contactService.serviceId;
    } else if (conversation != nil) {
        ZNGLogError(@"Unexpected conversation class %@.  Unable to find feed ID to subscribe for Socket IO udpates.", [conversation class]);
    }
    
    ZNGLogDebug(@"Setting active feed to %@", feedId);
    [socketClient emit:@"setActiveFeed" withItems:@[@{ @"feedId" : feedId, @"eventListRecordLimit" : @0 }]];
}

- (void) unsubscribeFromFeedUpdates
{
    [self subscribeForFeedUpdatesForConversation:nil];
}

#pragma mark - Typing indicator
- (void) userDidType:(NSString *)input
{
    if (![self.activeConversation isKindOfClass:[ZNGConversationServiceToContact class]]) {
        ZNGLogWarn(@"%@ was called, but the current conversation is a %@.  Ignoring.", NSStringFromSelector(_cmd), [self.activeConversation class]);
        return;
    }
    
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.activeConversation;

    NSString * description = nil;
    
    if (([input length] > 0) && (conversation.session.userAuthorization != nil)) {
        description = [NSString stringWithFormat:@"%@ is responding", [conversation.session.userAuthorization displayName]];
    }
    
    NSString * event = ([input length] > 0) ? @"lockFeed" : @"unlockFeed";
    
    NSMutableDictionary * payload = [[NSMutableDictionary alloc] init];
    payload[@"feedId"] = conversation.contact.contactId;
    payload[@"serviceId"] = conversation.service.serviceId;
    payload[@"pendingResponse"] = input;
    payload[@"description"] = description;
    
    [socketClient emit:event withItems:@[payload]];
}

- (void) userClearedInput
{
    [self userDidType:nil];
}

#pragma mark - Sockety goodness
- (void) socketEvent:(SocketAnyEvent *)event
{
    ZNGLogVerbose(@"Socket event of type %@: %@", [event class], event);
}

- (void) socketDidConnectWithData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    ZNGLogInfo(@"Web socket connected.");
    [socketClient emit:@"bindNodeController" withItems:@[@"dashboard.inbox"]];
}

- (void) socketDidBindNodeController
{
    ZNGLogDebug(@"Node controller bind succeeded.");
    if (self.activeConversation != nil) {
        [self subscribeForFeedUpdatesForConversation:self.activeConversation];
    }
}

- (void) socketDidEncounterErrorWithData:(NSArray *)data
{
    ZNGLogWarn(@"Web socket did receive error: %@", data);
    
    if ([[data firstObject] isKindOfClass:[NSString class]]) {
        NSString * errorString = [data firstObject];
        
        if ([errorString.lowercaseString containsString:@"session became invalid"]) {
            authSucceeded = NO;
            initializingSession = YES;
            [socketClient disconnect];
            [self connect];
        }
    }
}

- (void) socketDidDisconnect
{
    ZNGLogInfo(@"Web socket disconnected");
}

- (void) feedLocked:(NSArray *)data
{
    if (self.activeConversation == nil) {
        // We don't a conversation.  Who cares?
        return;
    }
    
    NSDictionary * info = [data firstObject];
    NSString * description = info[@"description"];
    
    ZingleAccountSession * accountSession = ([self.session isKindOfClass:[ZingleAccountSession class]]) ? (ZingleAccountSession *)self.session : nil;
    
    NSString * lockedByUserID = info[@"lockedByUuid"];
    NSString * meId = accountSession.userAuthorization.userId;
    
    BOOL lockedByMeMyselfAndI = (([meId length] > 0) && ([lockedByUserID isEqualToString:meId]));
    
    if (lockedByMeMyselfAndI) {
        ZNGLogVerbose(@"Received a feedLocked event, but it appears to be from our own typing.  Clearing any existing locked description.");
        self.activeConversation.lockedDescription = nil;
    } else {
        ZNGLogInfo(@"Conversation was locked: %@", description);
        self.activeConversation.lockedDescription = description;
    }
}

- (void) feedUnlocked:(NSArray *)data
{
    ZNGLogInfo(@"Conversation was unlocked");
    self.activeConversation.lockedDescription = nil;
}


@end
