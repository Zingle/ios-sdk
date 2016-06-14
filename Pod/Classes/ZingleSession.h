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

/*
 *  Designated initializer for a Zingle session object.  Provides URL overriding capabilities via baseUrl and isDebug flags that are ignored during release builds.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 *  @param baseUrl URL override for debug builds.  Used to allow settings bundle to specify a server target.  Ignored in release builds.
 *  @param isDebug Flag used when baseUrl is not provided to determine which server to target.
 */
- (instancetype) initWithToken:(nonnull NSString *)token key:(nonnull NSString *)key urlOverride:(nullable NSString *)baseUrl debugMode:(BOOL)isDebug;


@end
