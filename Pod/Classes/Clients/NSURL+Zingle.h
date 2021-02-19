//
//  NSURL+Zingle.h
//  Pods
//
//  Created by Jason Neel on 12/15/16.
//
//

#import <Foundation/Foundation.h>

@interface NSURL (Zingle)

/**
 *  Returns `YES` if the URL is a production Zingle URL.
 */
- (BOOL) isZingleProduction;

/**
 *  Returns the v1 API URL corresponding to the current Zingle URL.  Nil if the current URL does not appear to be a Zingle URL.
 */
- (NSURL * _Nullable)apiUrlV1;

/**
 *  Returns the v2 API URL corresponding to the current Zingle URL.  Nil if the current URL does not appear to be a Zingle URL.
 */
- (NSURL * _Nullable)apiUrlV2;

/**
 *  Returns the secure auth URL corresponding to the current Zingle URL.  Nil if the current URL does not appear to be a Zingle URL.
 */
- (NSURL * _Nullable)authUrl;

/**
 *  Returns the socket URL corresponding to the current Zingle URL.  Nil if the current URL does not appear to be a Zingle URL.
 */
- (NSURL * _Nullable)socketUrl;

/**
 *  Returns the web app URL corresponding to the current Zingle URL.  Nil if the current URL does not appear to be a Zingle URL.
 */
- (NSURL * _Nullable)webAppUrl;

/**
 *  Returns the URL used as the final successful redirect target for OAuth logins to the mobile app, using the "zingle://" scheme.
 */
+ (NSURL * _Nonnull)nativeLoginUrl;

@end
