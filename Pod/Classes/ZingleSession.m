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
    }
    
    return self;
}

@end
