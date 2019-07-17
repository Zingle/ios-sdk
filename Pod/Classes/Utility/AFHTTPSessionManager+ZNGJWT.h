//
//  AFHTTPSessionManager+ZNGJWT.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/17/19.
//

@import AFNetworking;

NS_ASSUME_NONNULL_BEGIN

@interface AFHTTPSessionManager (ZNGJWT)

/**
 *  Replaces any existing Authorization header with a Bearer JWT header
 */
- (void) applyJwt:(NSString *)jwt;

@end

NS_ASSUME_NONNULL_END
