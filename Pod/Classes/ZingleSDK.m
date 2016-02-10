//
//  ZingleSDK.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZingleSDK.h"
#import "ZNGConstants.h"

@interface ZingleSDK ()

@property(nonatomic, strong) AFHTTPSessionManager* sessionManager;

@end

@implementation ZingleSDK

+ (ZingleSDK*)sharedSDK
{
    static ZingleSDK* sharedSDK = nil;
    static dispatch_once_t sdkOnceToken;
    
    dispatch_once(&sdkOnceToken, ^{
        sharedSDK = [[ZingleSDK alloc] init];
    });
    
    return sharedSDK;
}

- (void)setToken:(NSString*)token andKey:(NSString*)key
{
    if (token == nil || key == nil) {
        [NSException raise:NSInvalidArgumentException format:@"ZingleSDK must be initialized with a token and key."];
    }
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kLiveBaseURL]];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
}

- (AFHTTPSessionManager*)sharedSessionManager
{
    if (!self.sessionManager) {
        [NSException raise:NSInvalidArgumentException format:@"ZingleSDK must be initialized with a token and key."];
    }
    
    return self.sessionManager;
}

@end
