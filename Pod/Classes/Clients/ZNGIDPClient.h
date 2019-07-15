//
//  ZNGIDPClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/14/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNGIDPClient : NSObject

- (id) init NS_UNAVAILABLE;

/**
 *  Initialize with a Zingle URL.  Note that this URL is just used to derive the correct IDP query URL and does not need to be any
 *  more specific than "ci-app.zingle.me" for a CI instance or "app.zingle.me" for production.
 */
- (instancetype) initWithZingleUrl:(NSURL *)url NS_DESIGNATED_INITIALIZER;

- (void) getIDPWithCode:(NSString *)code success:(void (^_Nullable)(NSURL * loginUrl))success failure:(void (^_Nullable)(NSError * error))failure;

@end

NS_ASSUME_NONNULL_END
