//
//  ZingleSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"
#import "ZNGLogging.h"
#import <AFNetworking/AFNetworking.h>
#import "ZNGAccountClient.h"
#import "ZNGContactServiceClient.h"
#import "ZNGNotificationsClient.h"
#import "ZNGServiceClient.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGAnalytics.h"

NSString * const LiveBaseURL = @"https://api.zingle.me/v1/";
NSString * const DebugBaseURL = @"https://qa-api.zingle.me/v1/";

NSString * const PushNotificationDeviceTokenUserDefaultsKey = @"zng_device_token";

static NSString * const ZNGAgentHeaderField = @"Zingle_Agent";
static NSString * const ZNGAgentValue = @"iOS_SDK";
static NSString * const ZNGClientIDField = @"x-zingle-client-id";
static NSString * const ZNGClientVersionField = @"x-zingle-client-version";

static const int zngLogLevel = ZNGLogLevelDebug;

@implementation ZingleSession
{
    BOOL isDebugging;
}

#pragma mark - Initializers
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key errorHandler:(nullable ZNGErrorHandler)errorHandler;
{
    NSParameterAssert(token);
    NSParameterAssert(key);
    
    self = [super init];
    
    if (self != nil) {
        _token = [token copy];
        _key = [key copy];
        _errorHandler = [errorHandler copy];
        
        NSString * defaultURL;
#ifdef DEBUG
        defaultURL = DebugBaseURL;
#else
        defaultURL = LiveBaseURL;
#endif
        
        NSString * urlString = [self urlOverride] ?: defaultURL;
        
        _jsonProcessingQueue = dispatch_queue_create("com.zingleme.sdk.jsonProcessing", NULL);
        
        NSURL * url = [NSURL URLWithString:urlString];
        
        [[ZNGAnalytics sharedAnalytics] setZingleURL:url];
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
        [_sessionManager.requestSerializer setValue:ZNGAgentValue forHTTPHeaderField:ZNGAgentHeaderField];
        [_sessionManager.requestSerializer setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:ZNGClientIDField];
        
        NSString * bundleVersion = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [_sessionManager.requestSerializer setValue:bundleVersion forHTTPHeaderField:ZNGClientVersionField];
        
        self.accountClient = [[ZNGAccountClient alloc] initWithSession:self];
        self.contactServiceClient = [[ZNGContactServiceClient alloc] initWithSession:self];
        self.notificationsClient = [[ZNGNotificationsClient alloc] initWithSession:self];
        self.notificationsClient.ignoreErrors = YES;
        self.serviceClient = [[ZNGServiceClient alloc] initWithSession:self];
        self.userAuthorizationClient = [[ZNGUserAuthorizationClient alloc] initWithSession:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *) urlOverride
{
    NSString * prefix = [[NSUserDefaults standardUserDefaults] valueForKey:@"zingle_server_prefix"];
    
    if ([prefix length] == 0) {
        return nil;
    }
    
    return [NSString stringWithFormat:@"https://%@-api.zingle.me/v1/", prefix];
}

#pragma mark - Setters
- (void) setMostRecentError:(ZNGError * _Nullable)mostRecentError
{
    _mostRecentError = mostRecentError;
    
    if ((mostRecentError != nil) && (self.errorHandler != nil)) {
        self.errorHandler(mostRecentError);
    }
}

#pragma mark - Push notifications
+ (void) setPushNotificationDeviceToken:(NSData *)pushNotificationDeviceToken
{
    [[NSUserDefaults standardUserDefaults] setValue:pushNotificationDeviceToken forKey:PushNotificationDeviceTokenUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) setPushNotificationDeviceToken:(NSData *)pushNotificationDeviceToken
{
    [[self class] setPushNotificationDeviceToken:pushNotificationDeviceToken];
}

- (NSData *) pushNotificationDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PushNotificationDeviceTokenUserDefaultsKey];
}

- (NSString *) _pushNotificationDeviceTokenAsHexString
{
    NSData * tokenData = [self pushNotificationDeviceToken];

    if (tokenData == nil) {
        return nil;
    }
 
    const uint8_t * bytes = [tokenData bytes];
    NSUInteger length = [tokenData length];
    NSMutableString * tokenString = [[NSMutableString alloc] initWithCapacity:(length * 2)];
    for (NSUInteger i=0; i < length; i++) {
        [tokenString appendString:[NSString stringWithFormat:@"%02.2hhx", bytes[i]]];
    }
        
    return tokenString;
}

- (void) _registerForPushNotificationsForServiceIds:(NSArray<NSString *> *)serviceIds removePreviousSubscriptions:(BOOL)removePrevious
{
    NSData * tokenData = [self pushNotificationDeviceToken];
    
    if (tokenData == nil) {
        ZNGLogDebug(@"Not registering for push notifications because no device token has been set.");
        return;
    }
    
    if ([serviceIds count] == 0) {
        ZNGLogInfo(@"No service IDs provided to register for push notifications method.  Ignoring.");
        return;
    }
    
    NSString * tokenString = [self _pushNotificationDeviceTokenAsHexString];
    
    void (^registerForNotifications)() = ^{
        [self.notificationsClient registerForNotificationsWithDeviceId:tokenString withServiceIds:serviceIds success:^(ZNGStatus *status) {
            ZNGLogDebug(@"Registered for push notifications successfully as %@", tokenString);
        } failure:^(ZNGError *error) {
            ZNGLogWarn(@"Failed to register for push notifications: %@", error);
        }];
    };
    
    if (!removePrevious) {
        registerForNotifications();
    } else {
        [self.notificationsClient unregisterForNotificationsWithDeviceId:tokenString success:^(ZNGStatus *status) {
            registerForNotifications();
        } failure:^(ZNGError *error) {
            ZNGLogWarn(@"Failed to unregister for push notifications before registering for a new service ID: %@\nAttempting to register the new ID anyway...", error);
            registerForNotifications();
        }];
    }
}

- (void) _unregisterForAllPushNotifications
{
    NSString * tokenString = [self _pushNotificationDeviceTokenAsHexString];

    if ([tokenString length] == 0) {
        ZNGLogDebug(@"Not unregistering for push notifications because no device token has been set.");
        return;
    }
    
    [self.notificationsClient unregisterForNotificationsWithDeviceId:tokenString success:nil failure:^(ZNGError *error) {
        ZNGLogWarn(@"Unable to unregister for push notifications: %@", error);
    }];
}

- (void) notifyPushNotificationReceived:(NSNotification *)notification
{
    ZNGLogInfo(@"Push notification received: %@", notification.userInfo);
}


@end
