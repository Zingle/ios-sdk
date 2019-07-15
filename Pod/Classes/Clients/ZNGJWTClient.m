//
//  ZNGJWTClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/19.
//

#import "ZNGJWTClient.h"
#import "ZingleSession.h"
#import "NSURL+Zingle.h"

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

- (void) acquireZingleJwtForUser:(NSString *)user
                        password:(NSString *)password
                         success:(void (^_Nullable)(NSString * jwt))success
                         failure:(void (^_Nullable)(NSError * error))failure
{
    AFHTTPSessionManager * authedSession = [session copy];
    [authedSession.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
    
    _requestPending = YES;
    [authedSession POST:@"token" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
    
    // TODO: Check if the JWT can actually be refreshed.  We may not have visibility into that yet.
    
    AFHTTPSessionManager * authedSession = [session copy];
    [authedSession.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", jwt] forHTTPHeaderField:@"Authorization"];
    
    [authedSession GET:@"token/refresh" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString * jwt = responseObject[@"token"];
        
        if ([jwt length] == 0) {
            NSString * errorDescription = @"JWT refresh returned 200, but no token could be found in the response.";
            SBLogError(@"%@", errorDescription);
            
            if (failure != nil) {
                failure([NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorDescription}]);
            }
            
            return;
        }
        
        SBLogInfo(@"Received %ud byte refreshed JWT", (unsigned int)[jwt length]);
        
        if (success != nil) {
            success(jwt);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        SBLogError(@"Unable to refresh JWT: %@", [error localizedDescription]);
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

@end
