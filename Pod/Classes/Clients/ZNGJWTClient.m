//
//  ZNGJWTClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/19.
//

#import "ZNGJWTClient.h"
#import "ZingleSession.h"
#import "NSURL+Zingle.h"
#import "NSString+ZNGJWT.h"

@import AFNetworking;
@import SBObjectiveCWrapper;

@implementation ZNGJWTClient
{
    AFHTTPSessionManager * session;
}

- (instancetype) initWithZingleURL:(NSURL *)exampleUrl
{
    self = [super init];
    
    if (self != nil) {
        NSURL * url = [exampleUrl apiUrlV2];
        
        session = [ZingleSession anonymousSessionManagerWithURL:url];
    }
    
    return self;
}

- (NSURL *)url
{
    return session.baseURL;
}

- (void) acquireJwtFromOauthProvider:(NSString *)oauthProvider
                               token:(NSString *)token
                             success:(void (^_Nullable)(NSString * jwt))success
                             failure:(void (^_Nullable)(NSError * error))failure
{
    AFHTTPSessionManager * authedSession = [session copy];
    NSDictionary * parameters = @{
        @"provider": oauthProvider,
        @"token": token,
    };
    
    _requestPending = YES;
    [authedSession POST:@"oauth/exchange" parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self handleJwtSuccess:task responseObject:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self->_requestPending = NO;
        SBLogError(@"Failed to acquire a JWT from %@ token", oauthProvider);
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

// Somewhere consistent to handle the JWT sanity checking code
- (void) handleJwtSuccess:(NSURLSessionDataTask * _Nonnull)task
           responseObject:(id _Nullable)responseObject
                  success:(void (^_Nullable)(NSString * jwt))success
                  failure:(void (^_Nullable)(NSError * error))failure
{
    self->_requestPending = NO;
    NSString * jwt = responseObject[@"token"];
    
    if ([jwt length] == 0) {
        NSString * errorDescription = [NSString stringWithFormat:@"Server returned 200 when a JWT was requested, but there is no \"token\" in the response: %@", responseObject];
        SBLogError(@"%@", errorDescription);
        
        if (failure != nil) {
            failure([NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorDescription}]);
        }
        
        return;
    }
    
    SBLogInfo(@"Received a %ud-byte JWT", (unsigned int)[jwt length]);
    if (success != nil) {
        success(jwt);
    }
}

- (void) acquireJwtForUser:(NSString *)user
                  password:(NSString *)password
                   success:(void (^_Nullable)(NSString * jwt))success
                   failure:(void (^_Nullable)(NSError * error))failure
{
    AFHTTPSessionManager * authedSession = [session copy];
    [authedSession.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
    
    _requestPending = YES;
    [authedSession POST:@"token" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self handleJwtSuccess:task responseObject:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self->_requestPending = NO;
        SBLogError(@"Failed to acquire a JWT for %@: %@", user, [error localizedDescription]);
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

- (void) refreshJwt:(NSString *)jwt success:(void (^_Nullable)(NSString * jwt))success failure:(void (^_Nullable)(NSError * error))failure
{
    if (self.requestPending) {
        SBLogWarning(@"refreshJwt: was called while a JWT request of some sort is already over the wire.  Ignoring.");
        return;
    }
    
    NSDate * refreshExpiration = [jwt jwtRefreshExpiration];
    
    if (refreshExpiration == nil) {
        SBLogWarning(@"Unable to determine refrehs window for the refreshing JWT.  This may fail.");
    } else {
        if ([refreshExpiration timeIntervalSinceNow] <= 0.0) {
            NSString * description = [NSString stringWithFormat:@"Unable to refresh JWT.  Its refresh window closed at %@", refreshExpiration];
            SBLogWarning(@"%@", description);
            
            if (failure != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError * error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: description}];
                    failure(error);
                });
            }
            
            return;
        }
    }
    
    AFHTTPSessionManager * authedSession = [session copy];
    [authedSession.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", jwt] forHTTPHeaderField:@"Authorization"];
    
    _requestPending = YES;
    
    [authedSession GET:@"token/refresh" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self handleJwtSuccess:task responseObject:responseObject success:success failure:failure];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        SBLogError(@"Unable to refresh JWT: %@", [error localizedDescription]);
        self->_requestPending = NO;
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

@end
