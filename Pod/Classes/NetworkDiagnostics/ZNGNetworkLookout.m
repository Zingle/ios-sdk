//
//  ZNGNetworkLookout.m
//  Pods
//
//  Created by Jason Neel on 4/18/17.
//
//

#import "ZNGNetworkLookout.h"
#import "ZingleAccountSession.h"
#import "ZNGSocketClient.h"
#import "ZNGLogging.h"
#import "ZNGReachability.h"
#import "ZNGUserAuthorizationClient.h"

// Override the readonly status property so we get a free KVO setter
@interface ZNGNetworkLookout()
@property (nonatomic, assign) ZNGNetworkLookoutStatus status;
@end

static const NSTimeInterval delayAfterLoginBeforeCheckingSocket = 3.0;

static const int zngLogLevel = ZNGLogLevelDebug;

@implementation ZNGNetworkLookout
{
    NSTimer * checkSocketAfterDelayTimer;
}

- (void) setStatus:(ZNGNetworkLookoutStatus)status
{
    if (_status != status) {
        ZNGLogDebug(@"Status changing from %@ to %@", [self debugDescriptionForStatus:_status], [self debugDescriptionForStatus:status]);
        _status = status;
    }
}

- (NSString *) debugDescriptionForStatus:(ZNGNetworkLookoutStatus)status
{
    switch (status) {
        case ZNGNetworkStatusConnected:
            return @"Connected";
        case ZNGNetworkStatusZingleAPIUnreachable:
            return @"API unreachable";
        case ZNGNetworkStatusInternetUnreachable:
            return @"Internet unreachable";
        case ZNGNetworkStatusZingleSocketDisconnected:
            return @"Socket disconnected";
        case ZNGNetworkStatusUnknown:
        default:
            return @"Unknown";
    }
}

#pragma mark - Status changes
- (void) recordLogin
{
    // Set status to connected.  This will allow the socket connection some time to connect.
    self.status = ZNGNetworkStatusConnected;
    
    // If our socket server has not yet connected (likely,) we will delay and then check it again before marking failure
    if (!self.session.socketClient.connected) {
        [self checkSocketAfterDelay];
    }
}

- (void) checkSocketAfterDelay
{
    [checkSocketAfterDelayTimer invalidate];
    checkSocketAfterDelayTimer = [NSTimer scheduledTimerWithTimeInterval:delayAfterLoginBeforeCheckingSocket
                                                                  target:self
                                                                selector:@selector(checkSocketConnectionSomeTimeAfterLogin:)
                                                                userInfo:nil
                                                                 repeats:NO];
}

- (void) checkSocketConnectionSomeTimeAfterLogin:(NSTimer *)timer
{
    checkSocketAfterDelayTimer = nil;
    
    if (self.session == nil) {
        ZNGLogInfo(@"We do not have a session object set, so we are unable to verify socket server status.");
        return;
    }
    
    if (self.session.socketClient.connected) {
        // Looks like we recovered.  Hooray!
        self.status = ZNGNetworkStatusConnected;
        return;
    }
    
    // We have a problem.  Diagnose and report.
    [self diagnoseFailure];
}

- (void) recordSocketConnected
{
    // Everything is great now!
    self.status = ZNGNetworkStatusConnected;
    
    [checkSocketAfterDelayTimer invalidate];
    checkSocketAfterDelayTimer = nil;
}

- (void) recordSocketDisconnected
{
    // If we do not have a session object set, we have to immediately mark this as a problem (since we are unable to recheck in a moment.)
    if (self.session == nil) {
        ZNGLogInfo(@"Socket disconnected.  We do not have a session weak reference, so this is immediately being marked as a connection failure.");
        [self diagnoseFailure];
        return;
    }
    
    // We do have a session, so we will delay a moment to give the socket a chance to recover
    [self checkSocketAfterDelay];
}

#pragma mark - Diagnosis
- (void) diagnoseFailure
{
    // Do they even have internet access?
    ZNGReachability * internetReachability = [ZNGReachability reachabilityForInternetConnection];
    
    if ([internetReachability currentReachabilityStatus] == NotReachable) {
        self.status = ZNGNetworkStatusInternetUnreachable;
        return;
    }
    
    // They have internet access.  We will first mark this as a socket connection failure.
    self.status = ZNGNetworkStatusZingleSocketDisconnected;
    
    // We will then check if we can even reach the API
    if (self.session.userAuthorizationClient != nil) {
        [self.session.userAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
            ZNGLogInfo(@"We are still able to reach the API.  This looks like a socket only problem.  Leaving status as Socket Disconnected.");
        } failure:^(ZNGError *error) {
            ZNGLogInfo(@"Unable to reach Zingle API: %@", error);
            self.status = ZNGNetworkStatusZingleAPIUnreachable;
        }];
    }
}

@end
