//
//  ZNGIDPClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/14/19.
//

#import "ZNGIDPClient.h"
#import "ZingleSession.h"
#import "NSURL+Zingle.h"

@import AFNetworking;
@import SBObjectiveCWrapper;

@implementation ZNGIDPClient
{
    AFHTTPSessionManager * session;
}

- (instancetype) initWithZingleUrl:(NSURL *)url
{
    self = [super init];
    
    if (self != nil) {
        session = [ZingleSession anonymousSessionManagerWithURL:[url apiUrlV2]];
    }
    
    return self;
}

- (void) getIDPWithCode:(NSString *)code success:(void (^_Nullable)(NSURL * loginUrl))success failure:(void (^_Nullable)(NSError * error))failure
{
    NSString * path = [NSString stringWithFormat:@"saml/idps/lookup?domainCode=%@", [code stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [session GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSURL * signOnUrl = [NSURL URLWithString:responseObject[@"signOnUri"]];
        
        if (signOnUrl == nil) {
            NSString * errorDescription = [NSString stringWithFormat:@"Unable to find login URL for \"%@\" IDP: %@", code, responseObject];
            SBLogError(@"%@", errorDescription);
            
            if (failure != nil) {
                failure([NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorDescription}]);
            }
            
            return;
        }
        
        SBLogInfo(@"Found login URL of %@ for %@", [signOnUrl absoluteString], code);
        
        if (success != nil) {
            success(signOnUrl);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        SBLogError(@"Unable to retrieve IDP for %@: %@", code, [error localizedDescription]);
        
        if (failure != nil) {
            failure(error);
        }
    }];
}

@end
