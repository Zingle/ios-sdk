//
//  AFHTTPSessionManager+ZNGJWT.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/17/19.
//

#import "AFHTTPSessionManager+ZNGJWT.h"

@import SBObjectiveCWrapper;

@implementation AFHTTPSessionManager (ZNGJWT)

- (void) applyJwt:(NSString *)jwt
{
    static NSString * const AuthHeaderKey = @"Authorization";
    NSString * existingAuthHeader = [self.requestSerializer valueForHTTPHeaderField:AuthHeaderKey];
    [self.requestSerializer clearAuthorizationHeader];

    if ([jwt length] > 0) {
        NSString * value = [NSString stringWithFormat:@"Bearer %@", jwt];
        [self.requestSerializer setValue:value forHTTPHeaderField:AuthHeaderKey];
    } else {
        if ([existingAuthHeader length] > 0) {
            SBLogWarning(@"Clearing existing authorization header due to nil JWT");
        } // else we're replacing nil with nil
    }
}

@end
