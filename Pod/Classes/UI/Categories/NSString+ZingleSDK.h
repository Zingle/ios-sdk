//
//  NSString+ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (ZingleSDK)

/**
 *  @return A copy of the receiver with all leading and trailing whitespace removed.
 */
- (NSString *)zng_stringByTrimingWhitespace;

@end
