//
//  ZNGSocketClient.m
//  Pods
//
//  Created by Jason Neel on 12/15/16.
//
//

#import "ZNGSocketClient.h"
#import "ZingleSession.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "NSURL+Zingle.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGConversationContactToService.h"
#import "ZingleAccountSession.h"
#import "ZNGUserAuthorization.h"
#import "ZNGInboxStatistician.h"

@import SBObjectiveCWrapper;
@import SocketIO;

@interface ZNGSocketClient()
@property (nonatomic, assign) BOOL connected;
@end

@implementation ZNGSocketClient
{
    SocketManager * socketManager;
    
    int currentServiceNumericId;
    
    NSString * authPath;
    NSString * nodePath;
    
    // YES if we are currently waiting on our initial auth request
    BOOL initializingSession;
    
    // YES if we have completed an auth request and set our session cookies
    BOOL authSucceeded;
    
    NSUInteger authFailureCount;
    NSTimer * authRetryTimer;
}

- (id) initWithSession:(ZingleSession *)session
{
    self = [super init];
    
    if (self != nil) {
        _session = session;
        
#ifndef DEBUG
        _ignoreCurrentUserTypingIndicator = YES;
#endif 
        
        NSString * zinglePrefix = [session.sessionManager.baseURL zingleServerPrefix];
        
        if (zinglePrefix == nil) {
            SBLogWarning(@"ZingleSession's base URL of %@ does not appear to be a Zingle URL.  Using production Zingle URL.", session.sessionManager.baseURL);
        }
        
        if ([zinglePrefix length] > 0) {
            authPath = [NSString stringWithFormat:@"https://%@-app.zingle.me/", zinglePrefix];
            nodePath = [NSString stringWithFormat:@"https://%@-app.zingle.me:8000", zinglePrefix];
        } else {
            authPath = @"https://secure.zingle.me/";
            nodePath = @"https://socket.zingle.me/";
        }
        
        SBLogDebug(@"Auth path is %@, node path is %@", authPath, nodePath);
    }
    
    return self;
}

- (BOOL) active
{
    int status = [socketManager status];
    return ((status == SocketIOStatusConnected) || (status == SocketIOStatusConnecting) || (initializingSession));
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
    SBLogVerbose(@"Request session cookie through a POST...");
    
    if (initializingSession) {
        SBLogDebug(@"Already starting connection.  Ignoring call to %s", __func__);
        return;
    }
    
    authSucceeded = NO;
    initializingSession = YES;
    
    NSURL * url = [NSURL URLWithString:authPath];
    
    AFHTTPSessionManager * session = [ZingleSession anonymousSessionManagerWithURL:url];
    [session.requestSerializer setAuthorizationHeaderFieldWithUsername:self.session.token password:self.session.key];
    session.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    // If we have ever switched from, for example, qa-zingle.zingle.me to zingle.zingle.me, NSHTTPCookieStorage will give us the cookie from the old instance since they share a domain.
    // Bad NSHTTPCookieStorage.  Bad.
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] removeCookiesSinceDate:[NSDate dateWithTimeIntervalSince1970:0.0]];
    
    [session POST:@"auth" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        SBLogDebug(@"Auth request succeeded.");
        self->authSucceeded = YES;
        [self _connectSocket];
        self->initializingSession = NO;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self->initializingSession = NO;
        
        if (error != nil) {
            SBLogWarning(@"Error sending request to auth URL: %@", error.localizedDescription);
            return;
        }
        
        SBLogWarning(@"Request to auth at %@ failued for an unknown reason.", self->authPath);
    }];
    
    [self _uncoverNumericIdForCurrentService];
}

// The socket server is terribly rude and often requires numeric IDs.  We can find our current service's numeric ID
//  leaked through the v2 API.
- (void) _uncoverNumericIdForCurrentService
{
    if (![self.session isKindOfClass:[ZingleAccountSession class]]) {
        SBLogInfo(@"Neglecting to find service numeric ID because we do not have a ZingleAccountSession.");
        return;
    }

    ZingleAccountSession * session = (ZingleAccountSession *)self.session;
    
    if ([session.service.serviceId length] == 0) {
        SBLogWarning(@"Neglecting to find service numeric ID because there is no UUID for the current service.");
        return;
    }
    
    NSString * v2ApiString = [session.urlString stringByReplacingOccurrencesOfString:@"v1" withString:@"v2"];
    AFHTTPSessionManager * httpSession = [ZingleSession anonymousSessionManagerWithURL:[NSURL URLWithString:v2ApiString]];
    [httpSession.requestSerializer setAuthorizationHeaderFieldWithUsername:self.session.token password:self.session.key];
    
    NSString * path = [NSString stringWithFormat:@"services/%@", session.service.serviceId];
    [httpSession GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (([responseObject isKindOfClass:[NSDictionary class]]) && ([responseObject[@"id"] isKindOfClass:[NSNumber class]])) {
            // We found an ID!
            self->currentServiceNumericId = [responseObject[@"id"] intValue];
        } else {
            SBLogWarning(@"Unable to find service numeric ID in v2 API response.");
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        SBLogError(@"Error attempting to fetch service data from v2 API: %@", error);
    }];
}

- (void) _connectSocket
{
    NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:authPath]];
    SBLogVerbose(@"Copying %llu cookies from our auth connection to the web socket connection", (unsigned long long)[cookies count]);
    
#if DEBUG
    NSNumber * shouldLog = @YES;
#else
    NSNumber * shouldLog = @NO;
#endif
    
    socketManager = [[SocketManager alloc] initWithSocketURL:[NSURL URLWithString:nodePath] config:@{ @"cookies" : cookies, @"log" : shouldLog }];
    SocketIOClient * socketClient = [socketManager defaultSocket];
    
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
    
    [socketClient on:@"feedUpdated" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedFeedUpdated:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"feedCreated" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedFeedUpdated:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"refreshFeeds" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedRefreshFeeds:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"nodeControllerBindSuccess" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidBindNodeController];
    }];
    
    [socketClient on:@"eventListData" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedEventListData:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"serviceUpdated" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedServiceData:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"serviceUsersData" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedUserData:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"badgeData" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedBadgeData:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"userIsReplying" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf otherUserIsReplying:data];
    }];
    
    [socketClient on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidEncounterErrorWithData:data];
    }];
    
    [socketClient on:@"reconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketReconnecting];
    }];
    
    [socketClient on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf socketDidDisconnect];
    }];
    
    [socketClient connect];
}

- (void) disconnect
{
    authFailureCount = 0;
    [authRetryTimer invalidate];
    authRetryTimer = nil;
    [socketManager disconnect];
}

- (void) subscribeForFeedUpdatesForConversation:(ZNGConversation *)conversation
{
    if (![self connected]) {
        // We're not yet connected.  We will subscribe to an active conversation as soon as we connect.
        SBLogVerbose(@"%@ was called, but we are not yet connected.  Delaying subscription until a successful connection.", NSStringFromSelector(_cmd));
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
        SBLogError(@"Unexpected conversation class %@.  Unable to find feed ID to subscribe for Socket IO udpates.", [conversation class]);
    }
    
    SBLogDebug(@"Setting active feed to %@", feedId);
    [[socketManager defaultSocket] emit:@"setActiveFeed" with:@[@{ @"feedId" : feedId, @"eventListRecordLimit" : @0 }]];
}

- (void) unsubscribeFromFeedUpdates
{
    [self subscribeForFeedUpdatesForConversation:nil];
}

#pragma mark - Typing indicator
- (void) userDidType:(NSString *)input
{
    if ([input length] == 0) {
        SBLogInfo(@"%s was called with no user input.  No message is sent to socket for the user clearing input, so this is ignored.", __PRETTY_FUNCTION__);
        return;
    }
    
    if (![self.activeConversation isKindOfClass:[ZNGConversationServiceToContact class]]) {
        SBLogWarning(@"%@ was called, but the current conversation is a %@.  Ignoring.", NSStringFromSelector(_cmd), [self.activeConversation class]);
        return;
    }
    
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.activeConversation;
    
    NSString * event = @"userIsReplying";
    
    NSMutableDictionary * user = [[NSMutableDictionary alloc] init];
    [user setValue:conversation.session.userAuthorization.userId forKey:@"id"];
    [user setValue:conversation.session.userAuthorization.firstName forKey:@"first_name"];
    [user setValue:conversation.session.userAuthorization.lastName forKey:@"last_name"];
    [user setValue:conversation.session.userAuthorization.email forKey:@"username"];
    [user setValue:[conversation.session.userAuthorization displayName] forKey:@"display_name"];
    [user setValue:[conversation.session.userAuthorization.avatarUri absoluteString] forKey:@"avatar_asset"];
    
    NSMutableDictionary * payload = [[NSMutableDictionary alloc] init];
    payload[@"feedId"] = (conversation.sequentialId > 0) ? @(conversation.sequentialId) : conversation.contact.contactId;
    payload[@"serviceId"] = conversation.service.serviceId;
    payload[@"type"] = @"message";
    payload[@"user"] = user;
    
    SBLogInfo(@"Emitting %@ for feed %@", event, conversation.contact.contactId);
    [[socketManager defaultSocket] emit:event with:@[payload]];
}

- (void) userClearedInput
{
    // No message is sent to socket for the user clearing input as of July 2016.
}

#pragma mark - Sockety goodness
- (void) socketEvent:(SocketAnyEvent *)event
{
    SBLogDebug(@"%p received socket event of type %@", self, event.event);
    SBLogVerbose(@"%@", event);
}

- (void) socketDidConnectWithData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    authFailureCount = 0;
    [authRetryTimer invalidate];
    authRetryTimer = nil;
    self.connected = YES;
    
    SBLogInfo(@"Web socket connected.");
    [[socketManager defaultSocket] emit:@"bindNodeController" with:@[@"dashboard.inbox"]];
}

- (void) socketDidBindNodeController
{
    if (currentServiceNumericId > 0) {
        [[socketManager defaultSocket] emit:@"setServiceIds" with:@[@[@(currentServiceNumericId)]]];
        [[socketManager defaultSocket] emit:@"getServiceBadges" with:@[@[@(currentServiceNumericId)]]];
    }
    
    SBLogDebug(@"Node controller bind succeeded.");
    if (self.activeConversation != nil) {
        [self subscribeForFeedUpdatesForConversation:self.activeConversation];
    }
}

// We do not actually process the event data from socket, but we can use this event to grab our sequential ID for the feed
//  (that does not exist in the API and should also not be used, even by socket, honestly.)
- (void) receivedEventListData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    SBLogDebug(@"Received event data.");
    
    NSDictionary * eventData = [data firstObject];
    NSNumber * feedId = eventData[@"requestFeedId"];
    
    if ([feedId integerValue] > 0) {
        self.activeConversation.sequentialId = [feedId integerValue];
    }
}

- (void) receivedFeedUpdated:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    NSDictionary * feedData = [data firstObject];
    NSDictionary * contact = feedData[@"contact"];
    NSString * feedId = ([contact isKindOfClass:[NSDictionary class]]) ? contact[@"uuid"] : nil;
    
    if ([feedId length] > 0) {
        NSDictionary * userInfo = @{ZingleConversationNotificationContactIdKey: feedId};
        SBLogDebug(@"Posting %@ notification for %@", ZingleConversationDataArrivedNotification, feedId);
        [[NSNotificationCenter defaultCenter] postNotificationName:ZingleConversationDataArrivedNotification object:nil userInfo:userInfo];
    } else {
        SBLogWarning(@"feedUpdated event arrived without a uuid: %@", data);
    }
}

- (void) receivedRefreshFeeds:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ZingleFeedListShouldBeRefreshedNotification object:nil];
}

- (void) receivedUserData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    if (![self.session isKindOfClass:[ZingleAccountSession class]]) {
        return;
    }
    
    ZingleAccountSession * session = (ZingleAccountSession *)self.session;
    
    NSMutableArray<ZNGUser *> * users = [[NSMutableArray alloc] init];
    
    for (NSDictionary * userDictionary in [data firstObject]) {
        [users addObject:[ZNGUser userFromSocketData:userDictionary]];
    }
    
    NSSortDescriptor * firstNameDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(firstName)) ascending:YES];
    NSSortDescriptor * lastNameDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(lastName)) ascending:YES];
    
    // Sort by first then last name
    [users sortUsingDescriptors:@[firstNameDescriptor, lastNameDescriptor]];
    
    session.users = users;
    
    // Update the user auth numeric ID while we're in here
    if (session.userAuthorization.numericId == 0) {
        for (ZNGUser * user in users) {
            if ([user.userId isEqualToString:session.userAuthorization.userId]) {
                session.userAuthorization.numericId = user.numericId;
                break;
            }
        }
    }
}

- (void) receivedBadgeData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    if (![self.session isKindOfClass:[ZingleAccountSession class]]) {
        return;
    }

    ZingleAccountSession * session = (ZingleAccountSession *)self.session;
    [session.inboxStatistician updateWithSocketData:data];
}

- (void) receivedServiceData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    if ([self.session isKindOfClass:[ZingleAccountSession class]]) {
        [(ZingleAccountSession *)self.session updateCurrentService];
    }
}

- (void) socketDidEncounterErrorWithData:(NSArray *)data
{
    SBLogWarning(@"Web socket did receive error: %@", data);
    
    if ([[data firstObject] isKindOfClass:[NSString class]]) {
        NSString * errorString = [data firstObject];
        
        if ([errorString.lowercaseString containsString:@"session became invalid"]) {
            authSucceeded = NO;
            initializingSession = YES;
            [socketManager disconnect];
            
            authFailureCount++;
            [authRetryTimer invalidate];
            authRetryTimer = [NSTimer scheduledTimerWithTimeInterval:[self authRetryDelay] target:self selector:@selector(connect) userInfo:nil repeats:NO];
        }
    }
}

- (NSTimeInterval) authRetryDelay
{
    switch (authFailureCount) {
        case 0:
        case 1:
            return 1.0;
            
        case 2:
            return 5.0;
            
        case 4:
            return 10.0;
            
        default:
            return 30.0;
    }
}

- (void) socketReconnecting
{
    self.connected = NO;
}

- (void) socketDidDisconnect
{
    SBLogInfo(@"Web socket disconnected");
    self.connected = NO;
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
        SBLogVerbose(@"Received a feedLocked event, but it appears to be from our own typing.  Clearing any existing locked description.");
        self.activeConversation.lockedDescription = nil;
    } else {
        SBLogInfo(@"Conversation was locked: %@", description);
        self.activeConversation.lockedDescription = description;
    }
}

- (void) otherUserIsReplying:(NSArray *)dataArray
{
    if (self.activeConversation == nil) {
        // We don't a conversation.  Who cares?
        return;
    }
    
    NSDictionary * data = [dataArray firstObject];
    NSDictionary * userData = data[@"user"];
    BOOL isNote = [data[@"type"] isEqualToString:@"note"];
    
    if (userData[@"id"] == nil) {
        SBLogWarning(@"Received a userIsReplying notification with no user ID.  Ignoring: %@", data);
        return;
    }
    
    ZingleAccountSession * accountSession = ([self.session isKindOfClass:[ZingleAccountSession class]]) ? (ZingleAccountSession *)self.session : nil;
    ZNGUser * user = [ZNGUser userFromSocketData:userData];
    
    // The socket data currently uses sequential IDs instead of our UUIDs.  This means that we cannot check vs. our own ID.
    // Should we check vs. our email/username?
    if ((self.ignoreCurrentUserTypingIndicator) && ([user.email isEqualToString:accountSession.userAuthorization.email])) {
        SBLogDebug(@"Received a userIsReplying notification for our current user.  Ignoring.");
        return;
    }
    
    [self.activeConversation otherUserIsReplying:user isInternalNote:isNote];
}

- (void) feedUnlocked:(NSArray *)data
{
    SBLogInfo(@"Conversation was unlocked");
    self.activeConversation.lockedDescription = nil;
}


@end
