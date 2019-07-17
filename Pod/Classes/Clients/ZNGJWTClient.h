//
//  ZNGJWTClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNGJWTClient : NSObject

@property (nonatomic, readonly) BOOL requestPending;
@property (nonatomic, readonly) NSURL * url;

- (id) init NS_UNAVAILABLE;

/**
 *  Initialize with a Zingle URL.  Note that this URL is just used to derive the correct JWT URL and does not need to be any
 *  more specific than "ci-app.zingle.me" for a CI instance or "app.zingle.me" for production.
 */
- (instancetype) initWithZingleURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

- (void) acquireZingleJwtForUser:(NSString *)user
                        password:(NSString *)password
                         success:(void (^_Nullable)(NSString * jwt))success
                         failure:(void (^_Nullable)(NSError * error))failure;

- (void) refreshJwt:(NSString *)jwt
            success:(void (^_Nullable)(NSString * jwt))success
            failure:(void (^_Nullable)(NSError * error))failure;

@end

NS_ASSUME_NONNULL_END
