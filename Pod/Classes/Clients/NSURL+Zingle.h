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
 *  Returns the environment prefix for a Zingle URL.
 *
 *  For a URL such as "https://qa-api.zingle.me/" or "https://qa-secure.zingle.me/" this will return "qa"
 *  In the case of a production Zingle URL with no prefix, such as "https://secure.zingle.me/" this will return an empty string
 *  In the case of a non-Zingle URL such as "https://thing-stuff-place.something.poop" this will return nil
 */
- (NSString * _Nullable)zingleServerPrefix;

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

@end
