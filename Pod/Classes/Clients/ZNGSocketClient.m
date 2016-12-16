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
    
    BOOL wasConnectedWhenEnteringBackground;
}

- (id) initWithSession:(ZingleSession *)session
{
    self = [super init];
    
    if (self != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
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

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) active
{
    return ((socketClient.status == SocketIOClientStatusConnected) || (socketClient.status == SocketIOClientStatusConnecting) || (initializingSession));
}

- (BOOL) connected
{
    return (socketClient.status == SocketIOClientStatusConnected);
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
            
            NSData * errorData = error.userInfo[NSURLErrorFailingURLStringErrorKey];
            NSString * errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            
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
    
    [socketClient connect];
}

- (void) disconnect
{
    [socketClient disconnect];
}

#pragma mark - Sockety goodness
- (void) socketEvent:(SocketAnyEvent *)event
{
    ZNGLogVerbose(@"Socket event of type %@: %@", [event class], event);
}

- (void) socketDidConnectWithData:(NSArray *)data ackEmitter:(SocketAckEmitter *)ackEmitter
{
    ZNGLogInfo(@"Web socket connected.");
}

#pragma mark - Background handling
- (void) notifyDidEnterBackground:(NSNotification *)notification
{
    wasConnectedWhenEnteringBackground = [self connected];
}

- (void) notifyWillEnterForeground:(NSNotification *)notification
{
    if (wasConnectedWhenEnteringBackground) {
        [self connect];
    }
}


@end
