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

#if DEBUG
static const int zngLogLevel = ZNGLogLevelVerbose;
#else
static const int zngLogLevel = ZNGLogLevelWarning;
#endif

@implementation ZNGSocketClient
{
    SRWebSocket * webSocket;
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
    return ((initializingSession) || (webSocket.readyState == SR_OPEN) || (webSocket.readyState == SR_CONNECTING));
}

- (BOOL) connected
{
    return (webSocket.readyState == SR_OPEN);
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
    
    NSURL * url = [NSURL URLWithString:authPath];
    
    AFHTTPSessionManager * session = [ZingleSession anonymousSessionManagerWithURL:url];
    [session.requestSerializer setAuthorizationHeaderFieldWithUsername:self.session.token password:self.session.key];
    session.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [session POST:@"auth" parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        ZNGLogDebug(@"Auth request succeeded.");
        authSucceeded = YES;
        [self _connectSocket];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
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
    [webSocket close];
    
    NSURL * url = [NSURL URLWithString:nodePath];
    NSURL * authURL = [NSURL URLWithString:authPath];
    webSocket = [[SRWebSocket alloc] initWithURL:url];
    
    // Copy our cookies, most importantly including our session cookie, to the web socket before opening
    NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:authURL];
    ZNGLogVerbose(@"Copying %llu cookies from our auth connection to the web socket connection", (unsigned long long)[cookies count]);
    webSocket.requestCookies = cookies;
    
    webSocket.delegate = self;
    [webSocket open];
}

- (void) disconnect
{
    [webSocket close];
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

#pragma mark - SRWebSocket delegate
- (void) webSocketDidOpen:(SRWebSocket *)aWebSocket
{
    ZNGLogInfo(@"Web socket connection opened to %@", webSocket.url.absoluteString);
}

- (void) webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    ZNGLogInfo(@"Web socket closed because: %lld %@", (long long)code, reason);
}

- (void) webSocket:(SRWebSocket *)aWebSocket didFailWithError:(NSError *)error
{
    ZNGLogInfo(@"Web socket connection failed: %@", error.localizedDescription);
    
    // TODO: Detect an auth failure and try to re-request auth
}

- (void) webSocket:(SRWebSocket *)aWebSocket didReceiveMessage:(id)message
{
    ZNGLogVerbose(@"Received a %@", [message class]);
}

@end
