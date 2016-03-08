//
//  NSBundle+ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>

@interface NSBundle (ZingleSDK)

/**
 *  Returns a localized version of the string designated by the specified key and residing in the ZingleSDK table.
 *
 *  @param key The key for a string in the ZingleSDK table.
 *
 *  @return A localized version of the string designated by key in the ZingleSDK table.
 */
+ (NSString *)zng_localizedStringForKey:(NSString *)key;

@end
