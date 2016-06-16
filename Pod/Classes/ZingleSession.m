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

NSString * const LiveBaseURL = @"https://api.zingle.me/v1/";
NSString * const DebugBaseURL = @"https://qa-api.zingle.me/v1/";

NSString * const PushNotificationDeviceTokenUserDefaultsKey = @"zng_device_token";

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZingleSession
{
    BOOL isDebugging;
}

#pragma mark - Initializers
- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key
{
    self = [super init];
    
    if (self != nil) {
        _token = [token copy];
        _key = [token copy];
        NSString * urlString = LiveBaseURL;
        
        _jsonProcessingQueue = dispatch_queue_create("com.zingleme.sdk.jsonProcessing", NULL);
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
        [_sessionManager.requestSerializer setValue:@"iOS_SDK" forHTTPHeaderField:@"Zingle_Agent"];
        
        self.accountClient = [[ZNGAccountClient alloc] initWithSession:self];
        self.contactServiceClient = [[ZNGContactServiceClient alloc] initWithSession:self];
        self.notificationsClient = [[ZNGNotificationsClient alloc] initWithSession:self];
        self.serviceClient = [[ZNGServiceClient alloc] initWithSession:self];
        self.userAuthorizationClient = [[ZNGUserAuthorizationClient alloc] initWithSession:self];
    }
    
    return self;
}

#pragma mark - Push notifications
- (void) setPushNotificationDeviceToken:(NSString *)pushNotificationDeviceToken
{
    NSString * deviceToken = pushNotificationDeviceToken;
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@"<" withString:@""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@">" withString:@""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSUserDefaults standardUserDefaults] setValue:deviceToken forKey:PushNotificationDeviceTokenUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) pushNotificationDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:PushNotificationDeviceTokenUserDefaultsKey];
}

@end
