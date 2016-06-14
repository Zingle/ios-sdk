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

NSString * const LiveBaseURL = @"https://api.zingle.me/v1/";
NSString * const DebugBaseURL = @"https://qa-api.zingle.me/v1/";

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZingleSession
{
    AFHTTPSessionManager * sessionManager;
    BOOL isDebugging;
}

#pragma mark - Initializers
- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key
{
    return [self initWithToken:token key:key urlOverride:nil debugMode:NO];
}

- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key urlOverride:(nullable NSString *)baseUrl debugMode:(BOOL)isDebug
{
    self = [super init];
    
    if (self != nil) {
#ifdef DEBUG
        _baseUrl = [baseUrl copy];
        isDebugging = isDebug;
#else
        if (baseUrl != nil) {
            ZNGLogWarn(@"Base URl override was specified as \"%@,\" but this is a release build, so it is being ignored.", baseUrl);
        }
#endif
        
        _token = [token copy];
        _key = [token copy];
        NSString * urlString = [self _baseUrl];
        
        sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
        sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
        [sessionManager.requestSerializer setValue:@"iOS_SDK" forHTTPHeaderField:@"Zingle_Agent"];
    }
    
    return self;
}

- (NSString *) _baseUrl
{
    if ([_baseUrl length] > 0) {
        return _baseUrl;
    }
    
    return (isDebugging) ? DebugBaseURL : LiveBaseURL;
}

@end
