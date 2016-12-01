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
#import <objc/runtime.h>

NSString * const LiveBaseURL = @"https://api.zingle.me/v1/";
NSString * const DebugBaseURL = @"https://qa-api.zingle.me/v1/";

NSString * const PushNotificationDeviceTokenUserDefaultsKey = @"zng_device_token";

static NSString * const ZNGAgentHeaderField = @"Zingle_Agent";
static NSString * const ZNGAgentValue = @"iOS_SDK";
static NSString * const ZNGClientIDField = @"x-zingle-client-id";
static NSString * const ZNGClientVersionField = @"x-zingle-client-version";

static NSString * const DeviceTokenUpdatedNotification = @"DeviceTokenUpdatedNotification";

static const int zngLogLevel = ZNGLogLevelDebug;

@implementation ZingleSession
{
    BOOL isDebugging;
    
    // If we try to register for push notifications but do not have a device token, the relevant service IDs will be saved here.
    // If our device token is then set later, we will register for these services.
    NSArray<NSString *> * pushNotificationQueuedServiceIds;
}

#pragma mark - Push notification swizzle magic
static void (*_originalDidReceiveRemoteNotificationImplementation)(id, SEL, id, id) = NULL;

void __applicationDidReceiveRemoteNotification(id self, SEL _cmd, UIApplication * application, NSDictionary * userInfo)
{
    [ZingleSession handlePushNotifcation:userInfo];
    
    if (_originalDidReceiveRemoteNotificationImplementation != NULL) {
        _originalDidReceiveRemoteNotificationImplementation(self, _cmd, application, userInfo);
    }
}

+ (void) handlePushNotifcation:(NSDictionary *)userInfo
{
    if ([self pushNotificationIsRelevantToZingle:userInfo]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:nil userInfo:userInfo];
    }
}

+ (void) load
{
    // A somewhat arbitrary delay to ensure that the app delegate class has loaded.  Removing this delay frequently (maybe always) results in this class
    //  loading before the [[UIApplication sharedApplication] delegate] is set to a non nil value.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self swizzlePushNotificationMethods];
    });
}

+ (void) swizzlePushNotificationMethods
{
    Class appDelegateClass = [[[UIApplication sharedApplication] delegate] class];
    
    if (appDelegateClass == nil) {
        ZNGLogError(@"Unable to find app delegate class.  Push notifications cannot be swizzled.");
        return;
    }
    
    IMP replacementApplicationDidReceiveRemoteNotification = (IMP)__applicationDidReceiveRemoteNotification;
    Method didReceiveRemoteNotificationMethod = class_getInstanceMethod(appDelegateClass, NSSelectorFromString(@"application:didReceiveRemoteNotification:"));
    IMP originalIMP = method_setImplementation(didReceiveRemoteNotificationMethod, replacementApplicationDidReceiveRemoteNotification);
    _originalDidReceiveRemoteNotificationImplementation = (void (*)(id, SEL, id, id))originalIMP;
}
        
+ (BOOL) pushNotificationIsRelevantToZingle:(NSDictionary *)userInfo
{
    return [userInfo[@"aps"][@"category"] isEqualToString:@"Zingle"];
}

#pragma mark - Initializers
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key
{
    NSParameterAssert(token);
    NSParameterAssert(key);
    
    self = [super init];
    
    if (self != nil) {
        _urlString = LiveBaseURL;
        _token = [token copy];
        _key = [key copy];
        
        _jsonProcessingQueue = dispatch_queue_create("com.zingleme.sdk.jsonProcessing", NULL);
        
        _sessionManager = [[self class] anonymousSessionManagerWithURL:[NSURL URLWithString:self.urlString]];
        [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
        
        self.accountClient = [[ZNGAccountClient alloc] initWithSession:self];
        self.contactServiceClient = [[ZNGContactServiceClient alloc] initWithSession:self];
        self.notificationsClient = [[ZNGNotificationsClient alloc] initWithSession:self];
        self.notificationsClient.ignoreErrors = YES;
        self.serviceClient = [[ZNGServiceClient alloc] initWithSession:self];
        self.userAuthorizationClient = [[ZNGUserAuthorizationClient alloc] initWithSession:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyDeviceTokenRegistered:) name:DeviceTokenUpdatedNotification object:nil];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) logout
{
    [self _unregisterForAllPushNotifications];
}

- (void) setUrlString:(NSString *)urlString
{
    NSURL * url = [NSURL URLWithString:urlString];
    
    if (url == nil) {
        ZNGLogError(@"Unable to set URL to %@", urlString);
        return;
    }
    
    _urlString = urlString;
    
    if (![self.sessionManager.baseURL isEqual:url]) {
        ZNGLogInfo(@"Creating new AF HTTP session manager for new URL of %@", urlString);
        self.sessionManager = [[self class] anonymousSessionManagerWithURL:url];
        [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.token password:self.key];
    }
}

/**
 *  Returns a session manager with all appropriate meta data.  Can be used for a normal login session or for an anonymous request such as a password reset.
 */
+ (AFHTTPSessionManager *) anonymousSessionManagerWithURL:(NSURL *)url
{
    [[ZNGAnalytics sharedAnalytics] setZingleURL:url];

    AFHTTPSessionManager * session = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    session.responseSerializer = [AFJSONResponseSerializer serializer];
    session.requestSerializer = [AFJSONRequestSerializer serializer];
    [session.requestSerializer setValue:ZNGAgentValue forHTTPHeaderField:ZNGAgentHeaderField];
    [session.requestSerializer setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:ZNGClientIDField];
    NSString * bundleVersion = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [session.requestSerializer setValue:bundleVersion forHTTPHeaderField:ZNGClientVersionField];

    return session;
}

+ (void) resetPasswordForEmail:(NSString *)email completion:(void (^_Nullable)(BOOL success))completion
{
    NSString * emailMinusWhitespace = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([emailMinusWhitespace length]  == 0) {
        ZNGLogError(@"Reset password called with a blank email address");
        completion(NO);
        return;
    }
    
    AFHTTPSessionManager * session = [self anonymousSessionManagerWithURL:[NSURL URLWithString:LiveBaseURL]];
    NSString * path = @"reset-password";
    NSDictionary * parameters = @{ @"email" : emailMinusWhitespace };
    
    [session POST:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSDictionary* statusDict = responseObject[@"status"];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:nil];
        
        if (status.statusCode != 200) {
            ZNGLogWarn(@"Server returned %llu when attempting to reset password.", (unsigned long long)status.statusCode);
            
            if (completion != nil) {
                completion(NO);
            }
            return;
        }
        
        ZNGLogInfo(@"Reset password succeeded.");
        
        if (completion != nil) {
            completion(YES);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        ZNGLogWarn(@"Reset password request failed: %@", [error localizedDescription]);
        
        if (completion != nil) {
            completion(NO);
        }
    }];
}

- (void) connect
{
    ZNGLogError(@"Connect called on abstract ZingleSession class.");
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
    
    if ([pushNotificationDeviceToken length] > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DeviceTokenUpdatedNotification object:pushNotificationDeviceToken];
    }
}

- (void) setPushNotificationDeviceToken:(NSData *)pushNotificationDeviceToken
{
    [[self class] setPushNotificationDeviceToken:pushNotificationDeviceToken];
}

- (void) notifyDeviceTokenRegistered:(NSNotification *)notification
{
    if ([pushNotificationQueuedServiceIds count] > 0) {
        [self _registerForPushNotificationsForServiceIds:pushNotificationQueuedServiceIds removePreviousSubscriptions:YES];
    }
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
        pushNotificationQueuedServiceIds = serviceIds;
        ZNGLogDebug(@"Not registering for push notifications because no device token has been set.");
        return;
    }
    
    pushNotificationQueuedServiceIds = nil;
    
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
    pushNotificationQueuedServiceIds = nil;
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
