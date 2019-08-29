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
#import "AFHTTPSessionManager+ZNGJWT.h"

@import SBObjectiveCWrapper;
@import SocketIO;

@interface ZNGSocketClient()
@property (nonatomic, assign) BOOL connected;
@end

@implementation ZNGSocketClient
{
    SocketManager * socketManager;
    
    int currentServiceNumericId;
    
    NSURL * socketUrl;
    
    BOOL needToSetServiceAndGetInitialBadges;
    BOOL controllerIsBound;
    NSUInteger bindRetryCount;
    NSTimer * bindRetryTimer;
}

- (id) initWithSession:(ZingleSession *)session
{
    self = [super init];
    
    if (self != nil) {
        _session = session;
        
#ifndef DEBUG
        _ignoreCurrentUserTypingIndicator = YES;
#endif 
        
        socketUrl = [session.sessionManager.baseURL socketUrl];
        
        if (socketUrl == nil) {
            SBLogError(@"Unable to derive socket URL from %@ URL", [session.sessionManager.baseURL absoluteString]);
            return nil;
        }
        
        SBLogDebug(@"Node path is %@", [socketUrl absoluteString]);
    }
    
    return self;
}

- (void) dealloc
{
    [self _cancelBindRetryTimer];
}

- (BOOL) active
{
    int status = [socketManager status];
    return ((status == SocketIOStatusConnected) || (status == SocketIOStatusConnecting));
}

- (void) setActiveConversation:(ZNGConversation *)activeConversation
{
    _activeConversation = activeConversation;
    [self subscribeForFeedUpdatesForConversation:activeConversation];
}

#pragma mark - Actions
- (void) connect
{
    [self _connectSocket];
}

- (void) disconnect
{
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
    
    SBLogDebug(@"Setting active feed to %@ via \"setActiveFeed\"", feedId);
    [[socketManager defaultSocket] emit:@"setActiveFeed" with:@[@{ @"feedId" : feedId, @"eventListRecordLimit" : @0 }]];
}

- (void) unsubscribeFromFeedUpdates
{
    [self subscribeForFeedUpdatesForConversation:nil];
}

#pragma mark - Connection lifecycle
- (void) _connectSocket
{
    [self _uncoverNumericIdForCurrentServiceIfNeeded];
    
    NSMutableDictionary<NSString *, id> * config = [[NSMutableDictionary alloc] init];
    config[@"log"] = @NO;
    config[@"connectParams"] = @{@"token": self.session.jwt};
    
    if (self.userAgent != nil) {
        config[@"extraHeaders"] = @{@"User-Agent": self.userAgent};
    }
    
    socketManager = [[SocketManager alloc] initWithSocketURL:socketUrl config:config];
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
    
    [socketClient on:@"userUpdated" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedCurrentUserData:data ackEmitter:ackEmitter];
    }];
    
    [socketClient on:@"serviceUsersData" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ackEmitter) {
        [weakSelf receivedUsersData:data ackEmitter:ackEmitter];
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
    
    [self _cancelBindRetryTimer];
    controllerIsBound = NO;
    bindRetryCount = 0;
    [socketClient connect];
}

// The socket server is terribly rude and requires numeric IDs.  We can find our current service's numeric ID
//  in the v2 API.
- (void) _uncoverNumericIdForCurrentServiceIfNeeded
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
    
    if (currentServiceNumericId > 0) {
        SBLogInfo(@"Neglecting to acquire service numeric ID because we already have it as %d", currentServiceNumericId);
        return;
    }
    
    AFHTTPSessionManager * httpSession = [ZingleSession anonymousSessionManagerWithURL:[socketUrl apiUrlV2]];
    [httpSession applyJwt:self.session.jwt];
    
    NSString * path = [NSString stringWithFormat:@"services/%@", session.service.serviceId];
    [httpSession GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (([responseObject isKindOfClass:[NSDictionary class]]) && ([responseObject[@"id"] isKindOfClass:[NSNumber class]])) {
            // We found an ID!
            self->currentServiceNumericId = [responseObject[@"id"] intValue];
            
            if (self->needToSetServiceAndGetInitialBadges) {
                [self _setServiceAndGetBadges];
            }
        } else {
            SBLogWarning(@"Unable to find service numeric ID in v2 API response.");
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        SBLogError(@"Error attempting to fetch service data from v2 API: %@", error);
    }];
}

- (void) socketDidConnectWithData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    SBLogInfo(@"Web socket connected.");
    controllerIsBound = NO;
    [self _bindNodeController];
}

- (void) _bindNodeController
{
    [self _cancelBindRetryTimer];
    
    if (controllerIsBound) {
        // We're done.  Hooray.
        return;
    }
    
    if (bindRetryCount > 0) {
        SBLogInfo(@"Retrying bindNodeController, attempt #%llu", (unsigned long long)bindRetryCount);
    }
    
    static NSString * const Binding = @"dashboard.inbox";
    SBLogDebug(@"Binding node controller to \"%@\"", Binding);
    [[socketManager defaultSocket] emit:@"bindNodeController" with:@[Binding]];
    [self _scheduleBindRetryTimer];
}

/**
 *  Starts a timer (using incremental backoff) to retry binding the node controller until it succeeds.
 *  This is sometimes necessary due to https://github.com/socketio/socket.io-client-swift/issues/1194
 */
- (void) _scheduleBindRetryTimer
{
    [self _cancelBindRetryTimer];
    
    __weak ZNGSocketClient * weakSelf = self;
    
    bindRetryTimer = [NSTimer scheduledTimerWithTimeInterval:[self _bindRetryInterval] repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf _bindNodeController];
    }];
    
    bindRetryCount++;
}

- (NSTimeInterval) _bindRetryInterval
{
    NSArray<NSNumber *> * const retryDelays = @[@1.0, @2.5, @5.0 , @10.0];
    
    NSNumber * delayNumber = (bindRetryCount < [retryDelays count]) ? retryDelays[bindRetryCount] : [retryDelays lastObject];
    return [delayNumber doubleValue];
}

- (void) _cancelBindRetryTimer
{
    [bindRetryTimer invalidate];
    bindRetryTimer = nil;
}

- (void) socketDidBindNodeController
{
    self.connected = YES;
    controllerIsBound = YES;
    [self _cancelBindRetryTimer];
    
    if (currentServiceNumericId > 0) {
        [self _setServiceAndGetBadges];
    } else {
        needToSetServiceAndGetInitialBadges = YES;
    }
    
    SBLogDebug(@"Node controller bind succeeded.");
    if (self.activeConversation != nil) {
        [self subscribeForFeedUpdatesForConversation:self.activeConversation];
    }
}

- (void) _setServiceAndGetBadges
{
    SBLogDebug(@"Emitting \"setServiceIds\" and \"getServiceBadges\" with ID %d", currentServiceNumericId);
    [[socketManager defaultSocket] emit:@"setServiceIds" with:@[@[@(currentServiceNumericId)]]];
    [[socketManager defaultSocket] emit:@"getServiceBadges" with:@[@[@(currentServiceNumericId)]]];
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

- (void) receivedCurrentUserData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    if (![self.session isKindOfClass:[ZingleAccountSession class]]) {
        return;
    }
    
    ZingleAccountSession * session = (ZingleAccountSession *)self.session;
    [session updateUserData];
}

- (void) receivedUsersData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
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
}

- (void) feedLocked:(NSArray *)data
{
    if (self.activeConversation == nil) {
        // We don't a conversation.  Who cares?
        return;
    }
    
    NSDictionary * info = [data firstObject];
    NSString * description = info[@"description"];
    BOOL isWorkflowLock = [info[@"lockedByType"] isEqual:@"Workflow"];
    
    if (!isWorkflowLock) {
        SBLogWarning(@"Unrecognized feedLocked type: %@", info[@"lockedByType"]);
        return;
    }
    
    ZingleAccountSession * accountSession = ([self.session isKindOfClass:[ZingleAccountSession class]]) ? (ZingleAccountSession *)self.session : nil;
    
    NSString * lockedByUserID = info[@"lockedByUuid"];
    NSString * meId = accountSession.userAuthorization.userId;
    
    BOOL lockedByMeMyselfAndI = (([meId length] > 0) && ([lockedByUserID isEqual:meId]));
    
    if (!lockedByMeMyselfAndI) {
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
    BOOL isNote = [data[@"type"] isEqual:@"note"];
    
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
