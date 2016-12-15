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
- (NSString *)zingleServerPrefix;

@end
