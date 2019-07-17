//
//  ZingleSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "ZNGAccountClient.h"
#import "ZNGContactServiceClient.h"
#import "ZNGNotificationsClient.h"
#import "ZNGServiceClient.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGAnalytics.h"
#import <objc/runtime.h>
#import "ZNGImageSizeCache.h"
#import <UserNotifications/UserNotifications.h>
#import "NSURL+Zingle.h"
#import "ZNGJWTClient.h"
#import "AFHTTPSessionManager+ZNGJWT.h"

@import SBObjectiveCWrapper;

NSString * const LiveBaseURL = @"https://api.zingle.me/v1/";

NSString * const PushNotificationDeviceTokenUserDefaultsKey = @"zng_device_token";

static NSString * const ZNGAgentHeaderField = @"Zingle_Agent";
static NSString * const ZNGAgentValue = @"iOS_SDK";
static NSString * const ZNGClientIDField = @"x-zingle-client-id";
static NSString * const ZNGClientVersionField = @"x-zingle-client-version";

static NSString * const DeviceTokenUpdatedNotification = @"DeviceTokenUpdatedNotification";

@implementation ZingleSession
{
    BOOL isDebugging;
    
    // If we try to register for push notifications but do not have a device token, the relevant service IDs will be saved here.
    // If our device token is then set later, we will register for these services.
    NSArray<NSString *> * pushNotificationQueuedServiceIds;
}

#pragma mark - Push notification swizzle magic
static void (*_originalDidReceiveRemoteNotificationImplementation)(id, SEL, id, id) = NULL;
static void (*_originalDidReceiveRemoteNotificationWithCompletionHandlerImplementation)(id, SEL, id, id, void *) = NULL;
static void (*_originalUserNotificationWillPresentImplementation)(id, SEL, id, id, void *) = NULL;

void __applicationDidReceiveRemoteNotification(id self, SEL _cmd, id application, id userInfo)
{
    [ZingleSession handlePushNotifcation:userInfo];
    
    if (_originalDidReceiveRemoteNotificationImplementation != NULL) {
        _originalDidReceiveRemoteNotificationImplementation(self, _cmd, application, userInfo);
    }
}

void __applicationDidReceiveRemoteNotificationWithCompletionHandler(id self, SEL _cmd, id application, id userInfo, void * completionHandler)
{
    [ZingleSession handlePushNotifcation:userInfo];
    
    if (_originalDidReceiveRemoteNotificationWithCompletionHandlerImplementation != NULL) {
        _originalDidReceiveRemoteNotificationWithCompletionHandlerImplementation(self, _cmd, application, userInfo, completionHandler);
    }
}

void __userNotificationWillPresent(id self, SEL _cmd, id notificationCenter, id notification, void * completion)
{
    if (@available(iOS 10.0, *)) {
        [ZingleSession handlePushWithUNNotification:notification];
    }
    
    if (_originalUserNotificationWillPresentImplementation != NULL) {
        _originalUserNotificationWillPresentImplementation(self, _cmd, notificationCenter, notification, completion);
    }
}

+ (void) handlePushNotifcation:(NSDictionary *)userInfo
{
    if ([self pushNotificationIsRelevantToZingle:userInfo]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:nil userInfo:userInfo];
    }
}

+ (void) handlePushWithUNNotification:(UNNotification *)notification NS_AVAILABLE_IOS(10.0)
{
    [self handlePushNotifcation:notification.request.content.userInfo];
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
    // First swizzle any UNUserNotificationCenter delegate
    if (@available(iOS 10.0, *)) {
        id<UNUserNotificationCenterDelegate> notificationCenterDelegate = [[UNUserNotificationCenter currentNotificationCenter] delegate];
        
        if (notificationCenterDelegate != nil) {
            Method userNotificationWillPresentMethod = class_getInstanceMethod([notificationCenterDelegate class], NSSelectorFromString(@"userNotificationCenter:willPresentNotification:withCompletionHandler:"));
            
            if (userNotificationWillPresentMethod != NULL) {
                IMP originalIMP = method_setImplementation(userNotificationWillPresentMethod, (IMP)__userNotificationWillPresent);
                _originalUserNotificationWillPresentImplementation = (void (*)(id, SEL, id, id, void *))originalIMP;
            }
        }
    }
    
    // Next we will be swizzling app delegate methods.  Find the app delegate.
    Class appDelegateClass = [[[UIApplication sharedApplication] delegate] class];
    
    if (appDelegateClass == nil) {
        SBLogError(@"Unable to find app delegate class.  Push notifications cannot be swizzled.");
        return;
    }

    Method didReceiveRemoteNotificationWithCompletionMethod = class_getInstanceMethod(appDelegateClass, NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:"));
    
    if (didReceiveRemoteNotificationWithCompletionMethod != NULL) {
        // This is an iOS 10.0+ app delegate that is a good boy and implements the newer version of application:didReceiveRemoteNotification:
        IMP replacementApplicationDidReceiveRemoteNotificationWithCompletionHandler = (IMP)__applicationDidReceiveRemoteNotificationWithCompletionHandler;
        IMP originalIMP = method_setImplementation(didReceiveRemoteNotificationWithCompletionMethod, replacementApplicationDidReceiveRemoteNotificationWithCompletionHandler);
        _originalDidReceiveRemoteNotificationWithCompletionHandlerImplementation = (void (*)(id, SEL, id, id, void *))originalIMP;
    }
    
    IMP replacementApplicationDidReceiveRemoteNotification = (IMP)__applicationDidReceiveRemoteNotification;
    Method didReceiveRemoteNotificationMethod = class_getInstanceMethod(appDelegateClass, NSSelectorFromString(@"application:didReceiveRemoteNotification:"));
    IMP originalIMP = method_setImplementation(didReceiveRemoteNotificationMethod, replacementApplicationDidReceiveRemoteNotification);
    _originalDidReceiveRemoteNotificationImplementation = (void (*)(id, SEL, id, id))originalIMP;
}
        
+ (BOOL) pushNotificationIsRelevantToZingle:(NSDictionary *)userInfo
{
    NSString * category = userInfo[@"aps"][@"category"];
    
    if (![category isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    // Does the category start with "Zingle"?
    NSRange zinglePrefixRange = [category rangeOfString:@"zingle" options:NSCaseInsensitiveSearch];
    return (zinglePrefixRange.location == 0);
}

#pragma mark - Initializers
- (nonnull instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key
{
    NSParameterAssert(token);
    NSParameterAssert(key);
    
    self = [super init];
    
    if (self != nil) {
        _token = [token copy];
        _key = [key copy];

        [self _commonInit];
    }
    
    return self;
}

- (nonnull instancetype) initWithJWT:(nonnull NSString *)jwt
{
    NSParameterAssert([jwt length] > 0);
    
    self = [super init];
    
    if (self != nil) {
        _jwt = jwt;
        
        [self _commonInit];
    }
    
    return self;
}

- (void) _commonInit
{
    _urlString = LiveBaseURL;
    
    _jsonProcessingQueue = dispatch_queue_create("com.zingleme.sdk.jsonProcessing", NULL);
    
    _sessionManager = [[self class] anonymousSessionManagerWithURL:[NSURL URLWithString:self.urlString]];
    [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.token password:self.key];
    
    NSString * v2ApiPath = [self.urlString stringByReplacingOccurrencesOfString:@"v1" withString:@"v2"];
    _v2SessionManager = [[self class] anonymousSessionManagerWithURL:[NSURL URLWithString:v2ApiPath]];
    [_v2SessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.token password:self.key];
    
    if ([self.jwt length] > 0) {
        [self applyJwtToSession];
    }
    
    self.accountClient = [[ZNGAccountClient alloc] initWithSession:self];
    self.contactServiceClient = [[ZNGContactServiceClient alloc] initWithSession:self];
    self.notificationsClient = [[ZNGNotificationsClient alloc] initWithSession:self];
    self.notificationsClient.ignoreErrors = YES;
    self.serviceClient = [[ZNGServiceClient alloc] initWithSession:self];
    self.userAuthorizationClient = [[ZNGUserAuthorizationClient alloc] initWithSession:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPushNotificationReceived:) name:ZNGPushNotificationReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyDeviceTokenRegistered:) name:DeviceTokenUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_notifyApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Allow our image size cache to load well ahead of it when it will be needed.
    [ZNGImageSizeCache sharedCache];
}

- (void) _notifyApplicationDidBecomeActive:(NSNotification *)notification
{
    [self vetJwtAfterResumingActive];
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
        SBLogError(@"Unable to set URL to %@", urlString);
        return;
    }
    
    _urlString = urlString;
    
    if (![self.sessionManager.baseURL isEqual:url]) {
        SBLogInfo(@"Creating new AF HTTP session manager for new URL of %@", urlString);
        self.sessionManager = [[self class] anonymousSessionManagerWithURL:url];
        [[ZNGAnalytics sharedAnalytics] setZingleURL:url];
        [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.token password:self.key];
        
        self.v2SessionManager = [[self class] anonymousSessionManagerWithURL:[url apiUrlV2]];
        [_v2SessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.token password:self.key];
        
        if ([self.jwt length] > 0) {
            [self applyJwtToSession];
        }
    }
}

#pragma mark - JWT
- (void)setJwt:(NSString *)jwt
{
    _jwt = [jwt copy];;
    
    if (jwt != nil) {
        [self applyJwtToSession];
        
        // TODO: Set a timer to refresh
    }
}

- (void) applyJwtToSession
{
    [self.sessionManager applyJwt:self.jwt];
    [self.v2SessionManager applyJwt:self.jwt];
}

/**
 *  Refreshes the current JWT if possible.  Note: Calling multiple times in rapid succession may result in one only call to the completion block.
 */
- (void) refreshJwt:(void (^_Nullable)(BOOL success, NSError * error))completion
{
    if (self.jwtClient.requestPending) {
        SBLogError(@"refreshJwt was called while a refresh operation is already pending.  Ignoring.");
        return;
    }
    
    NSURLComponents * desiredUrlComponents = [NSURLComponents componentsWithURL:self.sessionManager.baseURL resolvingAgainstBaseURL:YES];
    NSURLComponents * currentUrlComponents = (self.jwtClient != nil) ? [NSURLComponents componentsWithURL:self.jwtClient.url resolvingAgainstBaseURL:YES] : nil;
    
    // Do we need a new JWT client?  Note that this allows JWTClient mocking for unit testing.
    if (![currentUrlComponents.host isEqualToString:desiredUrlComponents.host]) {
        self.jwtClient = [[ZNGJWTClient alloc] initWithZingleURL:self.sessionManager.baseURL];
    }
    
    [self.jwtClient refreshJwt:self.jwt success:^(NSString * _Nonnull jwt) {
        SBLogInfo(@"JWT was successfully refreshed.");
        self.jwt = jwt;
        
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSError * _Nonnull error) {
        SBLogError(@"Error refreshing JWT: %@", [error localizedDescription]);
        self.jwt = nil;
        
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}

/**
 * If a JWT exists, this checks if it is valid/expired and refreshes if needed.  Safe to call in non-JWT sessions.
 */
- (void) vetJwtAfterResumingActive
{
    if ([self.jwt length] == 0) {
        // No JWT = nothing to do here
        return;
    }
    
    if ([self jwtIsValid]) {
        // It's still good.  Nothing to do.
        return;
    }
    
    // The JWT is no longer valid
    // Can we easily refresh it?
    if ([self jwtIsRefreshable]) {
        // TODO: Refresh JWT
        return;
    }
    
    // Our JWT is fully expired.  We must boot the user back to his IDP for authentication.
    // TODO: The above
}

- (BOOL) jwtIsValid
{
    // TODO: Implement beyond just checking for existence
    return ([self.jwt length] > 0);
}

- (BOOL) jwtIsRefreshable
{
    // TODO: Implement
    return YES;
}

#pragma mark - Session
/**
 *  Returns a session manager with all appropriate meta data.  Can be used for a normal login session or for an anonymous request such as a password reset.
 */
+ (AFHTTPSessionManager *) anonymousSessionManagerWithURL:(NSURL *)url
{
    AFHTTPSessionManager * session = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    session.responseSerializer = [AFJSONResponseSerializer serializer];
    session.requestSerializer = [AFJSONRequestSerializer serializer];
    [session.requestSerializer setValue:ZNGAgentValue forHTTPHeaderField:ZNGAgentHeaderField];
    [session.requestSerializer setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:ZNGClientIDField];
    NSString * bundleVersion = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [session.requestSerializer setValue:bundleVersion forHTTPHeaderField:ZNGClientVersionField];

    return session;
}

#pragma mark - Password Reset
+ (void) resetPasswordForEmail:(NSString *)email completion:(void (^_Nullable)(BOOL success))completion
{
    NSString * emailMinusWhitespace = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([emailMinusWhitespace length]  == 0) {
        SBLogError(@"Reset password called with a blank email address");
        completion(NO);
        return;
    }
    
    AFHTTPSessionManager * session = [self anonymousSessionManagerWithURL:[NSURL URLWithString:LiveBaseURL]];
    NSString * path = @"reset-password";
    NSDictionary * parameters = @{ @"email" : emailMinusWhitespace };
    
    [session POST:path parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSDictionary* statusDict = responseObject[@"status"];
        ZNGStatus *status = [MTLJSONAdapter modelOfClass:[ZNGStatus class] fromJSONDictionary:statusDict error:nil];
        
        if (status.statusCode != 200) {
            SBLogWarning(@"Server returned %llu when attempting to reset password.", (unsigned long long)status.statusCode);
            
            if (completion != nil) {
                completion(NO);
            }
            return;
        }
        
        SBLogInfo(@"Reset password succeeded.");
        
        if (completion != nil) {
            completion(YES);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        SBLogWarning(@"Reset password request failed: %@", [error localizedDescription]);
        
        if (completion != nil) {
            completion(NO);
        }
    }];
}

- (void) connect
{
    SBLogError(@"Connect called on abstract ZingleSession class.");
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
        SBLogDebug(@"Not registering for push notifications because no device token has been set.");
        return;
    }
    
    pushNotificationQueuedServiceIds = nil;
    
    if ([serviceIds count] == 0) {
        SBLogInfo(@"No service IDs provided to register for push notifications method.  Ignoring.");
        return;
    }
    
    NSString * tokenString = [self _pushNotificationDeviceTokenAsHexString];
    
    void (^registerForNotifications)(void) = ^{
        [self.notificationsClient registerForNotificationsWithDeviceId:tokenString withServiceIds:serviceIds success:^(ZNGStatus *status) {
            SBLogDebug(@"Registered for push notifications successfully as %@", tokenString);
        } failure:^(ZNGError *error) {
            SBLogWarning(@"Failed to register for push notifications: %@", error);
        }];
    };
    
    if (!removePrevious) {
        registerForNotifications();
    } else {
        [self.notificationsClient unregisterForNotificationsWithDeviceId:tokenString success:^(ZNGStatus *status) {
            registerForNotifications();
        } failure:^(ZNGError *error) {
            SBLogWarning(@"Failed to unregister for push notifications before registering for a new service ID: %@\nAttempting to register the new ID anyway...", error);
            registerForNotifications();
        }];
    }
}

- (void) _unregisterForAllPushNotifications
{
    pushNotificationQueuedServiceIds = nil;
    NSString * tokenString = [self _pushNotificationDeviceTokenAsHexString];

    if ([tokenString length] == 0) {
        SBLogDebug(@"Not unregistering for push notifications because no device token has been set.");
        return;
    }
    
    [self.notificationsClient unregisterForNotificationsWithDeviceId:tokenString success:nil failure:^(ZNGError *error) {
        SBLogWarning(@"Unable to unregister for push notifications: %@", error);
    }];
}

- (void) notifyPushNotificationReceived:(NSNotification *)notification
{
    SBLogInfo(@"Push notification received: %@", notification.userInfo);
}


@end
