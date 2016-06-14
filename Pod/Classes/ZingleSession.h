//
//  ZingleSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import <Foundation/Foundation.h>

/*
 *  This abstract class represents the current session with the Zingle API.  This must be initialized with a set of API credentials.
 *
 *  @see ZingleAccountSession
 *  @see ZingleContactSession
 */
@interface ZingleSession : NSObject

/*
 *  The token identifying the API user.  Immutable after initialization.
 */
@property (nonatomic, readonly, nonnull) NSString * token;

/*
 *  The security key/password of the current API user.  Immutable after initialization.
 */
@property (nonatomic, readonly, nonnull) NSString * key;

/*
 *  The base URL.  Can be overridden only in debug builds.  Immutable after initialization.
 */
@property (nonatomic, readonly, nullable) NSString * baseUrl;

/*
 *  Initializer for a Zingle session object.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 */
- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key;

@end
